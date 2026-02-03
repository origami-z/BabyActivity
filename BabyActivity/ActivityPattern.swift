//
//  ActivityPattern.swift
//  BabyActivity
//
//  Pattern analysis structures for smart reminders
//

import Foundation

/// Represents a learned pattern for a specific activity type
struct ActivityPattern: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var activityKind: ActivityKind
    var typicalIntervalMinutes: Double
    var confidenceScore: Double  // 0.0 to 1.0, higher = more confident
    var timeOfDayDistribution: [Int: Double]  // Hour (0-23) -> Probability (0.0-1.0)
    var sampleSize: Int  // Number of activities used to calculate this pattern
    var lastUpdated: Date

    /// Returns the most likely hours for this activity (top 3)
    var peakHours: [Int] {
        timeOfDayDistribution
            .sorted { $0.value > $1.value }
            .prefix(3)
            .map { $0.key }
    }

    /// Returns a human-readable description of the typical interval
    var intervalDescription: String {
        let hours = Int(typicalIntervalMinutes) / 60
        let minutes = Int(typicalIntervalMinutes) % 60

        if hours > 0 && minutes > 0 {
            return "\(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(minutes)m"
        }
    }

    /// Confidence level description
    var confidenceDescription: String {
        switch confidenceScore {
        case 0.8...1.0: return "High"
        case 0.5..<0.8: return "Medium"
        default: return "Low"
        }
    }
}

/// Represents a scheduled reminder to be sent to the user
struct ScheduledReminder: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var activityKind: ActivityKind
    var scheduledTime: Date
    var message: String
    var isRepeating: Bool
    var priority: ReminderPriority

    enum ReminderPriority: String, Codable, CaseIterable {
        case low
        case medium
        case high

        var notificationSound: Bool {
            self != .low
        }
    }
}

/// User settings for reminder behavior
struct ReminderSettings: Codable, Equatable {
    var isEnabled: Bool = true
    var enabledActivityKinds: Set<ActivityKind> = Set(ActivityKind.allCases)
    var sensitivity: Sensitivity = .balanced
    var quietHoursEnabled: Bool = true
    var quietHoursStart: Int = 22  // 10 PM
    var quietHoursEnd: Int = 7     // 7 AM
    var minimumConfidence: Double = 0.5  // Only show reminders above this confidence

    enum Sensitivity: String, Codable, CaseIterable {
        case conservative  // Fewer reminders, only high confidence
        case balanced      // Default behavior
        case aggressive    // More frequent reminders

        var description: String {
            switch self {
            case .conservative: return "Conservative"
            case .balanced: return "Balanced"
            case .aggressive: return "Aggressive"
            }
        }

        var detailedDescription: String {
            switch self {
            case .conservative: return "Fewer reminders, only when highly confident"
            case .balanced: return "Balanced reminder frequency"
            case .aggressive: return "More frequent reminders to help you stay on track"
            }
        }

        /// Multiplier for interval before sending reminder
        var intervalMultiplier: Double {
            switch self {
            case .conservative: return 1.2  // Wait 20% longer
            case .balanced: return 1.0
            case .aggressive: return 0.8    // Remind 20% earlier
            }
        }

        /// Minimum confidence required for this sensitivity level
        var minimumConfidence: Double {
            switch self {
            case .conservative: return 0.7
            case .balanced: return 0.5
            case .aggressive: return 0.3
            }
        }
    }

    /// Check if reminders are enabled for a specific activity kind
    func isEnabled(for kind: ActivityKind) -> Bool {
        isEnabled && enabledActivityKinds.contains(kind)
    }

    /// Check if current time is within quiet hours
    func isQuietHours(at date: Date = Date()) -> Bool {
        guard quietHoursEnabled else { return false }

        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)

        if quietHoursStart > quietHoursEnd {
            // Quiet hours span midnight (e.g., 22:00 to 07:00)
            return hour >= quietHoursStart || hour < quietHoursEnd
        } else {
            // Quiet hours within same day (e.g., 13:00 to 15:00)
            return hour >= quietHoursStart && hour < quietHoursEnd
        }
    }

    /// Get the next time outside of quiet hours
    func nextNonQuietTime(from date: Date = Date()) -> Date {
        guard isQuietHours(at: date) else { return date }

        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day, .hour], from: date)
        components.minute = 0
        components.second = 0

        // If we're in quiet hours, find when they end
        if quietHoursStart > quietHoursEnd {
            // Quiet hours span midnight
            let hour = calendar.component(.hour, from: date)
            if hour >= quietHoursStart {
                // It's late night, quiet hours end tomorrow morning
                components.day! += 1
            }
            components.hour = quietHoursEnd
        } else {
            components.hour = quietHoursEnd
        }

        return calendar.date(from: components) ?? date
    }
}

/// Prediction result from the activity predictor
struct ActivityPrediction: Identifiable, Equatable {
    var id: UUID = UUID()
    var activityKind: ActivityKind
    var predictedTime: Date
    var confidence: Double
    var basedOnPattern: ActivityPattern
    var message: String

    /// Time until the predicted activity
    var timeUntil: TimeInterval {
        predictedTime.timeIntervalSince(Date())
    }

    /// Human-readable time until prediction
    var timeUntilDescription: String {
        let minutes = Int(timeUntil / 60)
        let hours = minutes / 60
        let remainingMinutes = minutes % 60

        if hours > 0 && remainingMinutes > 0 {
            return "in \(hours)h \(remainingMinutes)m"
        } else if hours > 0 {
            return "in \(hours)h"
        } else if minutes > 0 {
            return "in \(minutes)m"
        } else {
            return "now"
        }
    }

    /// Whether this prediction is overdue
    var isOverdue: Bool {
        timeUntil < 0
    }

    /// Generate the reminder message
    static func generateMessage(for kind: ActivityKind, timeSinceLast: TimeInterval) -> String {
        let hours = Int(timeSinceLast / 3600)
        let minutes = Int((timeSinceLast.truncatingRemainder(dividingBy: 3600)) / 60)

        let timeString: String
        if hours > 0 && minutes > 0 {
            timeString = "\(hours)h \(minutes)m"
        } else if hours > 0 {
            timeString = "\(hours) hours"
        } else {
            timeString = "\(minutes) minutes"
        }

        switch kind {
        case .sleep:
            return "Baby might be getting sleepy. Last sleep ended \(timeString) ago."
        case .milk:
            return "It's been \(timeString) since the last feeding."
        case .wetDiaper, .dirtyDiaper:
            return "Time to check the diaper. Last change was \(timeString) ago."
        case .solidFood:
            return "Baby usually eats around this time."
        case .tummyTime:
            return "Good time for tummy time! Last session was \(timeString) ago."
        case .bathTime:
            return "Time for baby's bath."
        case .medicine:
            return "Time for baby's medicine."
        }
    }
}
