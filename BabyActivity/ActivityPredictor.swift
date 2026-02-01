//
//  ActivityPredictor.swift
//  BabyActivity
//
//  Pattern learning and prediction engine for smart reminders
//

import Foundation

/// Analyzes activity patterns and predicts when the next activity should occur
@MainActor
class ActivityPredictor: ObservableObject {
    @Published private(set) var patterns: [ActivityKind: ActivityPattern] = [:]
    @Published private(set) var predictions: [ActivityPrediction] = []
    @Published private(set) var lastAnalysisDate: Date?

    private let minimumSampleSize = 5  // Need at least 5 activities to establish pattern
    private let maximumDaysToAnalyze = 14  // Only look at last 2 weeks of data

    // MARK: - Pattern Analysis

    /// Analyzes activities to learn patterns for all activity kinds
    func analyzePatterns(from activities: [Activity]) {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -maximumDaysToAnalyze, to: Date())!
        let recentActivities = activities.filter { $0.timestamp >= cutoffDate }

        for kind in ActivityKind.allCases {
            if let pattern = analyzePattern(for: kind, from: recentActivities) {
                patterns[kind] = pattern
            }
        }

        lastAnalysisDate = Date()
    }

    /// Analyzes pattern for a specific activity kind
    func analyzePattern(for kind: ActivityKind, from activities: [Activity]) -> ActivityPattern? {
        let kindActivities = activities
            .filter { $0.kind == kind }
            .sorted { $0.timestamp < $1.timestamp }

        guard kindActivities.count >= minimumSampleSize else {
            return nil
        }

        // Calculate intervals between activities
        let intervals = calculateIntervals(kindActivities)
        guard !intervals.isEmpty else { return nil }

        // Calculate typical interval (median is more robust than mean)
        let sortedIntervals = intervals.sorted()
        let medianInterval = sortedIntervals[sortedIntervals.count / 2]

        // Calculate time of day distribution
        let timeDistribution = calculateTimeDistribution(kindActivities)

        // Calculate confidence based on consistency
        let confidence = calculateConfidence(intervals, medianInterval: medianInterval)

        return ActivityPattern(
            activityKind: kind,
            typicalIntervalMinutes: medianInterval,
            confidenceScore: confidence,
            timeOfDayDistribution: timeDistribution,
            sampleSize: kindActivities.count,
            lastUpdated: Date()
        )
    }

    /// Calculate intervals between consecutive activities in minutes
    private func calculateIntervals(_ activities: [Activity]) -> [Double] {
        guard activities.count >= 2 else { return [] }

        var intervals: [Double] = []
        for i in 1..<activities.count {
            // For activities with duration, use end time; otherwise use timestamp
            let previousEnd: Date
            if let endTimestamp = activities[i-1].endTimestamp {
                previousEnd = endTimestamp
            } else {
                previousEnd = activities[i-1].timestamp
            }

            let currentStart = activities[i].timestamp
            let intervalMinutes = currentStart.timeIntervalSince(previousEnd) / 60

            // Only include reasonable intervals (> 0 and < 24 hours)
            if intervalMinutes > 0 && intervalMinutes < 24 * 60 {
                intervals.append(intervalMinutes)
            }
        }
        return intervals
    }

    /// Calculate the probability distribution of activity times by hour
    private func calculateTimeDistribution(_ activities: [Activity]) -> [Int: Double] {
        var hourCounts: [Int: Int] = [:]

        // Initialize all hours to 0
        for hour in 0..<24 {
            hourCounts[hour] = 0
        }

        // Count activities by hour
        for activity in activities {
            let hour = Calendar.current.component(.hour, from: activity.timestamp)
            hourCounts[hour, default: 0] += 1
        }

        // Convert to probabilities
        let total = Double(activities.count)
        var distribution: [Int: Double] = [:]
        for (hour, count) in hourCounts {
            distribution[hour] = Double(count) / total
        }

        return distribution
    }

    /// Calculate confidence score based on interval consistency
    private func calculateConfidence(_ intervals: [Double], medianInterval: Double) -> Double {
        guard !intervals.isEmpty, medianInterval > 0 else { return 0 }

        // Calculate coefficient of variation (CV)
        let mean = intervals.reduce(0, +) / Double(intervals.count)
        let variance = intervals.map { pow($0 - mean, 2) }.reduce(0, +) / Double(intervals.count)
        let standardDeviation = sqrt(variance)
        let cv = standardDeviation / mean

        // Lower CV = more consistent = higher confidence
        // CV of 0 = perfect consistency = confidence 1.0
        // CV of 1 = high variability = confidence 0.0
        let confidence = max(0, min(1, 1.0 - cv))

        // Boost confidence slightly for larger sample sizes
        let sampleBonus = min(0.1, Double(intervals.count) / 100.0)

        return min(1.0, confidence + sampleBonus)
    }

    // MARK: - Predictions

    /// Predicts when the next activities should occur based on learned patterns
    func generatePredictions(from activities: [Activity], settings: ReminderSettings) -> [ActivityPrediction] {
        var newPredictions: [ActivityPrediction] = []

        for (kind, pattern) in patterns {
            guard settings.isEnabled(for: kind) else { continue }
            guard pattern.confidenceScore >= settings.sensitivity.minimumConfidence else { continue }

            if let prediction = predictNextActivity(for: kind, from: activities, pattern: pattern, settings: settings) {
                newPredictions.append(prediction)
            }
        }

        // Sort by predicted time
        predictions = newPredictions.sorted { $0.predictedTime < $1.predictedTime }
        return predictions
    }

    /// Predicts when the next activity of a specific kind should occur
    func predictNextActivity(for kind: ActivityKind, from activities: [Activity], pattern: ActivityPattern, settings: ReminderSettings) -> ActivityPrediction? {
        // Find the most recent activity of this kind
        let kindActivities = activities
            .filter { $0.kind == kind }
            .sorted { $0.timestamp > $1.timestamp }

        guard let lastActivity = kindActivities.first else {
            return nil
        }

        // Calculate when the last activity ended
        let lastActivityEnd: Date
        if let endTimestamp = lastActivity.endTimestamp {
            lastActivityEnd = endTimestamp
        } else {
            lastActivityEnd = lastActivity.timestamp
        }

        // Apply sensitivity multiplier to interval
        let adjustedInterval = pattern.typicalIntervalMinutes * settings.sensitivity.intervalMultiplier
        let predictedTime = lastActivityEnd.addingTimeInterval(adjustedInterval * 60)

        // Adjust for quiet hours
        var finalPredictedTime = predictedTime
        if settings.isQuietHours(at: predictedTime) {
            finalPredictedTime = settings.nextNonQuietTime(from: predictedTime)
        }

        // Calculate time since last activity for message
        let timeSinceLast = Date().timeIntervalSince(lastActivityEnd)
        let message = ActivityPrediction.generateMessage(for: kind, timeSinceLast: timeSinceLast)

        return ActivityPrediction(
            activityKind: kind,
            predictedTime: finalPredictedTime,
            confidence: pattern.confidenceScore,
            basedOnPattern: pattern,
            message: message
        )
    }

    // MARK: - Scheduled Reminders

    /// Generates scheduled reminders based on predictions and settings
    func getScheduledReminders(settings: ReminderSettings) -> [ScheduledReminder] {
        var reminders: [ScheduledReminder] = []

        for prediction in predictions {
            guard settings.isEnabled(for: prediction.activityKind) else { continue }
            guard prediction.confidence >= settings.minimumConfidence else { continue }

            // Don't schedule reminders in the past
            guard prediction.predictedTime > Date() else { continue }

            let priority: ScheduledReminder.ReminderPriority
            if prediction.confidence >= 0.8 {
                priority = .high
            } else if prediction.confidence >= 0.5 {
                priority = .medium
            } else {
                priority = .low
            }

            let reminder = ScheduledReminder(
                activityKind: prediction.activityKind,
                scheduledTime: prediction.predictedTime,
                message: prediction.message,
                isRepeating: false,
                priority: priority
            )

            reminders.append(reminder)
        }

        return reminders
    }

    // MARK: - Helpers

    /// Returns a summary of the learned patterns
    func patternSummary() -> String {
        guard !patterns.isEmpty else {
            return "No patterns learned yet. Keep logging activities to help the app learn your baby's schedule."
        }

        var summary = "Learned patterns:\n"
        for (kind, pattern) in patterns.sorted(by: { $0.key.rawValue < $1.key.rawValue }) {
            let confidence = pattern.confidenceDescription
            summary += "- \(kind.description.capitalized): every ~\(pattern.intervalDescription) (\(confidence) confidence)\n"
        }
        return summary
    }

    /// Check if we have enough data to make predictions
    var hasLearnedPatterns: Bool {
        !patterns.isEmpty
    }

    /// Get prediction for a specific activity kind
    func prediction(for kind: ActivityKind) -> ActivityPrediction? {
        predictions.first { $0.activityKind == kind }
    }
}

// MARK: - DataController Extension for Pattern Analysis

extension DataController {
    /// Analyzes activity patterns and returns learned patterns
    static func analyzeActivityPatterns(_ activities: [Activity], minimumSampleSize: Int = 5) -> [ActivityKind: ActivityPattern] {
        var patterns: [ActivityKind: ActivityPattern] = [:]

        for kind in ActivityKind.allCases {
            let kindActivities = activities
                .filter { $0.kind == kind }
                .sorted { $0.timestamp < $1.timestamp }

            guard kindActivities.count >= minimumSampleSize else { continue }

            // Calculate intervals
            var intervals: [Double] = []
            for i in 1..<kindActivities.count {
                let previousEnd: Date
                if let endTimestamp = kindActivities[i-1].endTimestamp {
                    previousEnd = endTimestamp
                } else {
                    previousEnd = kindActivities[i-1].timestamp
                }

                let currentStart = kindActivities[i].timestamp
                let intervalMinutes = currentStart.timeIntervalSince(previousEnd) / 60

                if intervalMinutes > 0 && intervalMinutes < 24 * 60 {
                    intervals.append(intervalMinutes)
                }
            }

            guard !intervals.isEmpty else { continue }

            // Calculate median interval
            let sortedIntervals = intervals.sorted()
            let medianInterval = sortedIntervals[sortedIntervals.count / 2]

            // Calculate time distribution
            var hourCounts: [Int: Int] = [:]
            for hour in 0..<24 { hourCounts[hour] = 0 }
            for activity in kindActivities {
                let hour = Calendar.current.component(.hour, from: activity.timestamp)
                hourCounts[hour, default: 0] += 1
            }
            let total = Double(kindActivities.count)
            var distribution: [Int: Double] = [:]
            for (hour, count) in hourCounts {
                distribution[hour] = Double(count) / total
            }

            // Calculate confidence
            let mean = intervals.reduce(0, +) / Double(intervals.count)
            let variance = intervals.map { pow($0 - mean, 2) }.reduce(0, +) / Double(intervals.count)
            let standardDeviation = sqrt(variance)
            let cv = mean > 0 ? standardDeviation / mean : 1.0
            let confidence = max(0, min(1, 1.0 - cv))

            patterns[kind] = ActivityPattern(
                activityKind: kind,
                typicalIntervalMinutes: medianInterval,
                confidenceScore: confidence,
                timeOfDayDistribution: distribution,
                sampleSize: kindActivities.count,
                lastUpdated: Date()
            )
        }

        return patterns
    }

    /// Calculates typical feeding interval in minutes
    static func typicalFeedingIntervalMinutes(_ activities: [Activity]) -> Double? {
        let intervals = feedingIntervals(activities)
        guard !intervals.isEmpty else { return nil }
        let sortedIntervals = intervals.map { $0.intervalMinutes }.sorted()
        return sortedIntervals[sortedIntervals.count / 2]
    }

    /// Calculates typical sleep duration in minutes
    static func typicalSleepDurationMinutes(_ activities: [Activity]) -> Double? {
        let sleepActivities = activities.filter { $0.kind == .sleep && $0.endTimestamp != nil }
        guard sleepActivities.count >= 3 else { return nil }

        let durations = sleepActivities.compactMap { activity -> Double? in
            guard let end = activity.endTimestamp else { return nil }
            return end.timeIntervalSince(activity.timestamp) / 60
        }.sorted()

        return durations[durations.count / 2]
    }
}
