//
//  FoundationModelService.swift
//  BabyActivity
//
//  On-device AI service using Apple's Foundation Models framework (iOS 26+)
//

import Foundation
import FoundationModels

/// Service for on-device AI-powered activity analysis using Foundation Models
@MainActor
class FoundationModelService: ObservableObject {
    static let shared = FoundationModelService()

    @Published private(set) var isAvailable: Bool = false
    @Published private(set) var lastInsight: String?
    @Published private(set) var isProcessing: Bool = false

    private var session: LanguageModelSession?

    init() {
        Task {
            await checkAvailability()
        }
    }

    // MARK: - Availability

    /// Check if Foundation Models are available on this device
    func checkAvailability() async {
        let availability = LanguageModelSession.Availability.current
        isAvailable = availability == .available
    }

    // MARK: - Activity Analysis

    /// Analyze activity patterns and generate insights using on-device AI
    func analyzeActivityPatterns(_ activities: [Activity], patterns: [ActivityKind: ActivityPattern]) async -> String? {
        guard isAvailable else {
            return nil
        }

        isProcessing = true
        defer { isProcessing = false }

        do {
            let session = LanguageModelSession()

            // Build context about the baby's activities
            let context = buildActivityContext(activities, patterns: patterns)

            let prompt = """
            You are a helpful baby care assistant analyzing activity patterns for a parent.

            Here is the recent activity data:
            \(context)

            Based on this data, provide a brief, helpful insight about the baby's schedule.
            Focus on one of these if relevant:
            - Sleep patterns (is baby getting enough sleep? any notable trends?)
            - Feeding schedule (regular intervals? sufficient intake?)
            - Diaper patterns (healthy frequency?)

            Keep your response to 2-3 sentences, friendly and reassuring.
            """

            let response = try await session.respond(to: prompt)
            lastInsight = response.content
            return response.content
        } catch {
            print("Foundation Models error: \(error)")
            return nil
        }
    }

    /// Generate a personalized reminder message using AI
    func generateSmartReminderMessage(for kind: ActivityKind, pattern: ActivityPattern, lastActivity: Activity) async -> String? {
        guard isAvailable else {
            return ActivityPrediction.generateMessage(for: kind, timeSinceLast: Date().timeIntervalSince(lastActivity.endTimestamp ?? lastActivity.timestamp))
        }

        isProcessing = true
        defer { isProcessing = false }

        do {
            let session = LanguageModelSession()

            let timeSinceLast = Date().timeIntervalSince(lastActivity.endTimestamp ?? lastActivity.timestamp)
            let hoursSince = timeSinceLast / 3600
            let typicalHours = pattern.typicalIntervalMinutes / 60

            let prompt = """
            Generate a brief, friendly reminder message for a parent about their baby's \(kind.description).

            Context:
            - Activity type: \(kind.description)
            - Time since last: \(String(format: "%.1f", hoursSince)) hours
            - Typical interval: \(String(format: "%.1f", typicalHours)) hours
            - Confidence in pattern: \(pattern.confidenceDescription)

            Write a single sentence that is:
            - Warm and supportive (not alarming)
            - Specific to the activity type
            - Mentions the time if relevant

            Just respond with the reminder message, nothing else.
            """

            let response = try await session.respond(to: prompt)
            return response.content
        } catch {
            // Fallback to standard message
            return ActivityPrediction.generateMessage(for: kind, timeSinceLast: Date().timeIntervalSince(lastActivity.endTimestamp ?? lastActivity.timestamp))
        }
    }

    /// Analyze sleep quality and provide recommendations
    func analyzeSleepQuality(_ sleepActivities: [Activity]) async -> SleepInsight? {
        guard isAvailable else { return nil }

        isProcessing = true
        defer { isProcessing = false }

        let recentSleep = sleepActivities
            .filter { $0.kind == .sleep && $0.endTimestamp != nil }
            .sorted { $0.timestamp > $1.timestamp }
            .prefix(14) // Last 2 weeks

        guard recentSleep.count >= 3 else { return nil }

        do {
            let session = LanguageModelSession()

            var sleepData = "Recent sleep sessions:\n"
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM d, h:mm a"

            for sleep in recentSleep {
                guard let end = sleep.endTimestamp else { continue }
                let duration = end.timeIntervalSince(sleep.timestamp) / 3600
                let hour = Calendar.current.component(.hour, from: sleep.timestamp)
                let isNightSleep = hour >= 19 || hour < 7

                sleepData += "- \(dateFormatter.string(from: sleep.timestamp)): \(String(format: "%.1f", duration)) hours (\(isNightSleep ? "night" : "day"))\n"
            }

            let prompt = """
            Analyze this baby's sleep data and provide insights:

            \(sleepData)

            Respond in JSON format with these fields:
            {
              "qualityScore": <1-5 rating>,
              "summary": "<one sentence summary>",
              "suggestion": "<one actionable suggestion>"
            }

            Consider: total sleep, day/night balance, consistency, and age-appropriate sleep needs.
            """

            let response = try await session.respond(to: prompt)

            // Parse the JSON response
            if let data = response.content.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                return SleepInsight(
                    qualityScore: json["qualityScore"] as? Int ?? 3,
                    summary: json["summary"] as? String ?? "Sleep patterns look normal.",
                    suggestion: json["suggestion"] as? String
                )
            }

            return nil
        } catch {
            print("Sleep analysis error: \(error)")
            return nil
        }
    }

    /// Predict optimal activity time based on patterns and current context
    func predictOptimalTime(for kind: ActivityKind, pattern: ActivityPattern, lastActivity: Activity?) async -> Date? {
        guard isAvailable, let lastActivity = lastActivity else {
            // Fallback to simple calculation
            if let last = lastActivity {
                let endTime = last.endTimestamp ?? last.timestamp
                return endTime.addingTimeInterval(pattern.typicalIntervalMinutes * 60)
            }
            return nil
        }

        isProcessing = true
        defer { isProcessing = false }

        do {
            let session = LanguageModelSession()

            let lastEnd = lastActivity.endTimestamp ?? lastActivity.timestamp
            let hoursSinceLast = Date().timeIntervalSince(lastEnd) / 3600
            let currentHour = Calendar.current.component(.hour, from: Date())

            // Find peak hours from distribution
            let peakHours = pattern.peakHours

            let prompt = """
            Determine the optimal time for the next \(kind.description) activity.

            Context:
            - Current time: \(currentHour):00
            - Hours since last \(kind.description): \(String(format: "%.1f", hoursSinceLast))
            - Typical interval: \(String(format: "%.0f", pattern.typicalIntervalMinutes)) minutes
            - Peak activity hours: \(peakHours.map { "\($0):00" }.joined(separator: ", "))

            Respond with just a number representing how many minutes from now would be ideal.
            Consider: the typical interval, current time of day, and peak hours.
            """

            let response = try await session.respond(to: prompt)

            if let minutes = Double(response.content.trimmingCharacters(in: .whitespacesAndNewlines)) {
                return Date().addingTimeInterval(minutes * 60)
            }

            return nil
        } catch {
            // Fallback
            let endTime = lastActivity.endTimestamp ?? lastActivity.timestamp
            return endTime.addingTimeInterval(pattern.typicalIntervalMinutes * 60)
        }
    }

    // MARK: - Helpers

    private func buildActivityContext(_ activities: [Activity], patterns: [ActivityKind: ActivityPattern]) -> String {
        var context = ""

        // Recent activity summary
        let today = Calendar.current.startOfDay(for: Date())
        let todayActivities = activities.filter { $0.timestamp >= today }

        context += "Today's activities:\n"
        for kind in ActivityKind.allCases {
            let count = todayActivities.filter { $0.kind == kind }.count
            if count > 0 {
                context += "- \(kind.description.capitalized): \(count) times\n"
            }
        }

        // Pattern summary
        context += "\nLearned patterns:\n"
        for (kind, pattern) in patterns {
            context += "- \(kind.description.capitalized): typically every \(pattern.intervalDescription), \(pattern.confidenceDescription.lowercased()) confidence\n"
        }

        // Last activities
        context += "\nMost recent activities:\n"
        let recentActivities = activities.sorted { $0.timestamp > $1.timestamp }.prefix(5)
        let formatter = RelativeDateTimeFormatter()
        for activity in recentActivities {
            context += "- \(activity.kind.description.capitalized) \(formatter.localizedString(for: activity.timestamp, relativeTo: Date()))\n"
        }

        return context
    }
}

// MARK: - Sleep Insight

struct SleepInsight: Identifiable, Equatable {
    let id = UUID()
    let qualityScore: Int  // 1-5
    let summary: String
    let suggestion: String?

    var qualityDescription: String {
        switch qualityScore {
        case 5: return "Excellent"
        case 4: return "Good"
        case 3: return "Average"
        case 2: return "Fair"
        default: return "Needs Attention"
        }
    }
}

// MARK: - Activity Predictor Extension

extension ActivityPredictor {
    /// Enhanced prediction using Foundation Models when available
    func generateEnhancedPredictions(from activities: [Activity], settings: ReminderSettings) async -> [ActivityPrediction] {
        // First, generate standard predictions
        let standardPredictions = generatePredictions(from: activities, settings: settings)

        // If Foundation Models is available, enhance messages
        guard FoundationModelService.shared.isAvailable else {
            return standardPredictions
        }

        var enhancedPredictions: [ActivityPrediction] = []

        for var prediction in standardPredictions {
            // Find the last activity for this kind
            let lastActivity = activities
                .filter { $0.kind == prediction.activityKind }
                .sorted { $0.timestamp > $1.timestamp }
                .first

            if let last = lastActivity,
               let enhancedMessage = await FoundationModelService.shared.generateSmartReminderMessage(
                   for: prediction.activityKind,
                   pattern: prediction.basedOnPattern,
                   lastActivity: last
               ) {
                prediction = ActivityPrediction(
                    id: prediction.id,
                    activityKind: prediction.activityKind,
                    predictedTime: prediction.predictedTime,
                    confidence: prediction.confidence,
                    basedOnPattern: prediction.basedOnPattern,
                    message: enhancedMessage
                )
            }

            enhancedPredictions.append(prediction)
        }

        predictions = enhancedPredictions
        return enhancedPredictions
    }
}
