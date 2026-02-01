//
//  PreviewContainer.swift
//  BabyActivity
//
//  Created by Zhihao Cui on 19/12/2024.
//

import Foundation
import SwiftData

@MainActor
class DataController {
    static let previewContainer: ModelContainer = {
        do {
            let schema = Schema([Activity.self, GrowthMeasurement.self, Milestone.self, Baby.self, FamilyMember.self])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            let container = try ModelContainer(for: schema, configurations: config)

            // Create a sample baby
            let sampleBaby = Baby(
                name: "Emma",
                birthDate: Calendar.current.date(byAdding: .month, value: -6, to: Date()) ?? Date(),
                ownerCloudKitID: "preview-user"
            )
            container.mainContext.insert(sampleBaby)

            // Add a sample family member
            _ = sampleBaby.addFamilyMember(
                cloudKitUserID: "family-member-1",
                displayName: "Partner",
                permission: .caregiver
            )

            for activity in simulatedActivities {
                container.mainContext.insert(activity)
            }

            return container
        } catch {
            fatalError("Failed to create model container for previewing: \(error.localizedDescription)")
        }
    }()
    
    
    static let sleepAcitivity = Activity(kind: .sleep, timestamp: Date().addingTimeInterval(Double(1) * 60 * -60), endTimestamp: Date().addingTimeInterval(Double(1) * 60 * -60) + 10*60)
    static let milkAcitivity = Activity(kind: .milk, timestamp: Date().addingTimeInterval(Double(2) * 60 * -60), endTimestamp: Date().addingTimeInterval(Double(1) * 60 * -60) + 10*60, amount: 50)
    static let wetDiaperActivity = Activity(kind: .wetDiaper, timestamp: Date().addingTimeInterval(Double(3) * 60 * -60))
    static let dirtyDiaperActivity = Activity(kind: .dirtyDiaper, timestamp: Date().addingTimeInterval(Double(4) * 60 * -60))
    static let solidFoodActivity = Activity(kind: .solidFood, timestamp: Date().addingTimeInterval(Double(5) * 60 * -60), foodType: "Banana puree")
    static let tummyTimeActivity = Activity(kind: .tummyTime, timestamp: Date().addingTimeInterval(Double(6) * 60 * -60), endTimestamp: Date().addingTimeInterval(Double(6) * 60 * -60) + 15*60)
    static let bathTimeActivity = Activity(kind: .bathTime, timestamp: Date().addingTimeInterval(Double(7) * 60 * -60))
    static let medicineActivity = Activity(kind: .medicine, timestamp: Date().addingTimeInterval(Double(8) * 60 * -60), medicineName: "Vitamin D", dosage: "1 drop")
    
    static let simulatedActivities: [Activity] = {
        var activities: [Activity] = []
        for i in 0...5 {
            let startingTimeInterval = Double(i) * 60 * -60 * 24 // -i day
            let hourInterval = Double(60 * 60)
            
            let startOfToday = Calendar.current.startOfDay(for: Date())
            
            activities.append(contentsOf: [
                // sleeps
                Activity(kind:.sleep, timestamp: startOfToday.addingTimeInterval(startingTimeInterval - hourInterval), endTimestamp: startOfToday.addingTimeInterval(startingTimeInterval + hourInterval * 0.5)), // cross-over from previous day
                Activity(kind:.sleep, timestamp: startOfToday.addingTimeInterval(startingTimeInterval + hourInterval * 2), endTimestamp: startOfToday.addingTimeInterval(startingTimeInterval + hourInterval * 3.5)),
                Activity(kind:.sleep, timestamp: startOfToday.addingTimeInterval(startingTimeInterval + hourInterval * 5), endTimestamp: startOfToday.addingTimeInterval(startingTimeInterval + hourInterval * 5.8)),
                Activity(kind:.sleep, timestamp: startOfToday.addingTimeInterval(startingTimeInterval + hourInterval * 9), endTimestamp: startOfToday.addingTimeInterval(startingTimeInterval + hourInterval * 9.6)),
                Activity(kind:.sleep, timestamp: startOfToday.addingTimeInterval(startingTimeInterval + hourInterval * 14), endTimestamp: startOfToday.addingTimeInterval(startingTimeInterval + hourInterval * 15.2)),
                Activity(kind:.sleep, timestamp: startOfToday.addingTimeInterval(startingTimeInterval + hourInterval * 17), endTimestamp: startOfToday.addingTimeInterval(startingTimeInterval + hourInterval * 18.1)),
                Activity(kind:.sleep, timestamp: startOfToday.addingTimeInterval(startingTimeInterval + hourInterval * 20.5), endTimestamp: startOfToday.addingTimeInterval(startingTimeInterval + hourInterval * 21.7)),
                
                // milk
                Activity(kind: .milk, timestamp: startOfToday.addingTimeInterval(startingTimeInterval + hourInterval * 1.5), endTimestamp: startOfToday.addingTimeInterval(startingTimeInterval + hourInterval * 1.9), amount: 30 * i),
                Activity(kind: .milk, timestamp: startOfToday.addingTimeInterval(startingTimeInterval + hourInterval * 6.5), endTimestamp: startOfToday.addingTimeInterval(startingTimeInterval + hourInterval * 7.2), amount: 30 * i),
                Activity(kind: .milk, timestamp: startOfToday.addingTimeInterval(startingTimeInterval + hourInterval * 11.2), endTimestamp: startOfToday.addingTimeInterval(startingTimeInterval + hourInterval * 11.9), amount: 30 * i),
                Activity(kind: .milk, timestamp: startOfToday.addingTimeInterval(startingTimeInterval + hourInterval * 15.7), endTimestamp: startOfToday.addingTimeInterval(startingTimeInterval + hourInterval * 16.3), amount: 30 * i),
                Activity(kind: .milk, timestamp: startOfToday.addingTimeInterval(startingTimeInterval + hourInterval * 20), endTimestamp: startOfToday.addingTimeInterval(startingTimeInterval + hourInterval * 20.2), amount: 30 * i),
                
                // diaper
                Activity(kind: .dirtyDiaper, timestamp: startOfToday.addingTimeInterval(startingTimeInterval + hourInterval * 1.1)),
                Activity(kind: .wetDiaper, timestamp: startOfToday.addingTimeInterval(startingTimeInterval + hourInterval * 3.7)),
                Activity(kind: .wetDiaper, timestamp: startOfToday.addingTimeInterval(startingTimeInterval + hourInterval * 6)),
                Activity(kind: .dirtyDiaper, timestamp: startOfToday.addingTimeInterval(startingTimeInterval + hourInterval * 9.9)),
                Activity(kind: .wetDiaper, timestamp: startOfToday.addingTimeInterval(startingTimeInterval + hourInterval * 15.4)),
                Activity(kind: .wetDiaper, timestamp: startOfToday.addingTimeInterval(startingTimeInterval + hourInterval * 19.4)),

                // tummy time
                Activity(kind: .tummyTime, timestamp: startOfToday.addingTimeInterval(startingTimeInterval + hourInterval * 4), endTimestamp: startOfToday.addingTimeInterval(startingTimeInterval + hourInterval * 4.25)),
                Activity(kind: .tummyTime, timestamp: startOfToday.addingTimeInterval(startingTimeInterval + hourInterval * 10), endTimestamp: startOfToday.addingTimeInterval(startingTimeInterval + hourInterval * 10.2)),

                // solid food (only for older baby simulation - days 0-2)
                Activity(kind: .solidFood, timestamp: startOfToday.addingTimeInterval(startingTimeInterval + hourInterval * 8), foodType: ["Banana puree", "Apple sauce", "Carrot puree", "Sweet potato", "Avocado", "Oatmeal"][i % 6], reactions: i == 3 ? "Mild rash" : nil),

                // bath time
                Activity(kind: .bathTime, timestamp: startOfToday.addingTimeInterval(startingTimeInterval + hourInterval * 18.5)),

                // medicine (vitamin D daily)
                Activity(kind: .medicine, timestamp: startOfToday.addingTimeInterval(startingTimeInterval + hourInterval * 7.5), medicineName: "Vitamin D", dosage: "1 drop")
            ])
        }
        return activities
    }()
    
    // Slice activities (with start/end time) into the same day, for calculation and chart
    static func sliceDataToPlot(sleepActivities: [Activity]) -> [PlotDuration] {
        var durations: [PlotDuration] = []
        for activity in sleepActivities {
            let start = activity.timestamp
            let startDay = Calendar.current.dateComponents([.day], from: start).day!
            let end = activity.endTimestamp ?? activity.timestamp
            let endDay = Calendar.current.dateComponents([.day], from: end).day!
            if (startDay == endDay) {
                durations.append(PlotDuration(start: start, end: end, id: UUID()))
            } else {
                let startOfEnd = Calendar.current.startOfDay(for: end)
                durations.append(PlotDuration(start: start, end: startOfEnd.addingTimeInterval(-1), id: UUID()))
                durations.append(PlotDuration(start: startOfEnd, end: end, id: UUID()))
            }
        }
        return durations
    }
    
    static func averageDurationPerDay(_ durations: [PlotDuration]) -> TimeInterval {
        guard !durations.isEmpty else { return 0 }
        // Group by full date (year, month, day) to avoid incorrectly grouping activities from different months
        let groupedByDay = Dictionary(grouping: durations, by: { Calendar.current.startOfDay(for: $0.start) })
        let totalDurationsPerDay = groupedByDay.values.map { $0.reduce(0) { $0 + $1.end.timeIntervalSince($1.start) } }
        return totalDurationsPerDay.mean()
    }
}

extension Array where Element: FloatingPoint {

    func mean() -> Element {
        guard !isEmpty else { return 0 }
        return reduce(0, +) / Element(count)
    }
}

struct PlotDuration:Identifiable {
    var start: Date
    var end: Date
    var id: UUID
}

// MARK: - Milk Analytics Helpers

struct DailyMilkData: Identifiable {
    var date: Date
    var totalAmount: Int
    var feedingCount: Int
    var averagePerFeeding: Double
    var id: Date { date }
}

struct FeedingInterval: Identifiable {
    var id: UUID = UUID()
    var from: Date
    var to: Date
    var intervalMinutes: Double
}

extension DataController {
    /// Groups milk activities by day and calculates daily totals
    static func milkDataByDay(_ activities: [Activity]) -> [DailyMilkData] {
        let milkActivities = activities.filter { $0.kind == .milk }
        guard !milkActivities.isEmpty else { return [] }

        let groupedByDay = Dictionary(grouping: milkActivities) {
            Calendar.current.startOfDay(for: $0.timestamp)
        }

        return groupedByDay.map { (date, activities) in
            let totalAmount = activities.compactMap { $0.amount }.reduce(0, +)
            let feedingCount = activities.count
            let averagePerFeeding = feedingCount > 0 ? Double(totalAmount) / Double(feedingCount) : 0
            return DailyMilkData(
                date: date,
                totalAmount: totalAmount,
                feedingCount: feedingCount,
                averagePerFeeding: averagePerFeeding
            )
        }.sorted { $0.date < $1.date }
    }

    /// Calculates average milk intake per feeding across all activities
    static func averageMilkPerFeeding(_ activities: [Activity]) -> Double {
        let milkActivities = activities.filter { $0.kind == .milk }
        let amounts = milkActivities.compactMap { $0.amount }
        guard !amounts.isEmpty else { return 0 }
        return Double(amounts.reduce(0, +)) / Double(amounts.count)
    }

    /// Calculates average daily milk intake
    static func averageDailyMilkIntake(_ activities: [Activity]) -> Double {
        let dailyData = milkDataByDay(activities)
        guard !dailyData.isEmpty else { return 0 }
        let totalAmounts = dailyData.map { Double($0.totalAmount) }
        return totalAmounts.mean()
    }

    /// Calculates intervals between feedings
    static func feedingIntervals(_ activities: [Activity]) -> [FeedingInterval] {
        let milkActivities = activities.filter { $0.kind == .milk }.sorted { $0.timestamp < $1.timestamp }
        guard milkActivities.count >= 2 else { return [] }

        var intervals: [FeedingInterval] = []
        for i in 1..<milkActivities.count {
            let from = milkActivities[i-1].timestamp
            let to = milkActivities[i].timestamp
            let intervalMinutes = to.timeIntervalSince(from) / 60
            intervals.append(FeedingInterval(from: from, to: to, intervalMinutes: intervalMinutes))
        }
        return intervals
    }

    /// Average time between feedings in minutes
    static func averageFeedingIntervalMinutes(_ activities: [Activity]) -> Double {
        let intervals = feedingIntervals(activities)
        guard !intervals.isEmpty else { return 0 }
        return intervals.map { $0.intervalMinutes }.mean()
    }
}

// MARK: - Diaper Analytics Helpers

struct DailyDiaperData: Identifiable {
    var date: Date
    var wetCount: Int
    var dirtyCount: Int
    var totalCount: Int
    var id: Date { date }
}

struct HourlyDiaperData: Identifiable {
    var hour: Int
    var wetCount: Int
    var dirtyCount: Int
    var id: Int { hour }
}

extension DataController {
    /// Groups diaper activities by day and calculates counts
    static func diaperDataByDay(_ activities: [Activity]) -> [DailyDiaperData] {
        let diaperActivities = activities.filter { $0.kind == .wetDiaper || $0.kind == .dirtyDiaper }
        guard !diaperActivities.isEmpty else { return [] }

        let groupedByDay = Dictionary(grouping: diaperActivities) {
            Calendar.current.startOfDay(for: $0.timestamp)
        }

        return groupedByDay.map { (date, activities) in
            let wetCount = activities.filter { $0.kind == .wetDiaper }.count
            let dirtyCount = activities.filter { $0.kind == .dirtyDiaper }.count
            return DailyDiaperData(
                date: date,
                wetCount: wetCount,
                dirtyCount: dirtyCount,
                totalCount: wetCount + dirtyCount
            )
        }.sorted { $0.date < $1.date }
    }

    /// Groups diaper activities by hour for time-of-day pattern analysis
    static func diaperDataByHour(_ activities: [Activity]) -> [HourlyDiaperData] {
        let diaperActivities = activities.filter { $0.kind == .wetDiaper || $0.kind == .dirtyDiaper }
        guard !diaperActivities.isEmpty else { return [] }

        let groupedByHour = Dictionary(grouping: diaperActivities) {
            Calendar.current.component(.hour, from: $0.timestamp)
        }

        return (0..<24).map { hour in
            let activities = groupedByHour[hour] ?? []
            let wetCount = activities.filter { $0.kind == .wetDiaper }.count
            let dirtyCount = activities.filter { $0.kind == .dirtyDiaper }.count
            return HourlyDiaperData(hour: hour, wetCount: wetCount, dirtyCount: dirtyCount)
        }
    }

    /// Average diapers per day
    static func averageDiapersPerDay(_ activities: [Activity]) -> Double {
        let dailyData = diaperDataByDay(activities)
        guard !dailyData.isEmpty else { return 0 }
        return dailyData.map { Double($0.totalCount) }.mean()
    }
}

// MARK: - Enhanced Sleep Analytics Helpers

struct SleepStretch: Identifiable {
    var id: UUID = UUID()
    var start: Date
    var end: Date
    var durationMinutes: Double
    var isNightSleep: Bool
}

extension DataController {
    /// Finds the longest sleep stretch
    static func longestSleepStretch(_ activities: [Activity]) -> SleepStretch? {
        let sleepActivities = activities.filter { $0.kind == .sleep && $0.endTimestamp != nil }
        guard !sleepActivities.isEmpty else { return nil }

        return sleepActivities.compactMap { activity -> SleepStretch? in
            guard let end = activity.endTimestamp else { return nil }
            let duration = end.timeIntervalSince(activity.timestamp) / 60
            let hour = Calendar.current.component(.hour, from: activity.timestamp)
            let isNight = hour >= 19 || hour < 7  // 7pm to 7am considered night
            return SleepStretch(start: activity.timestamp, end: end, durationMinutes: duration, isNightSleep: isNight)
        }.max { $0.durationMinutes < $1.durationMinutes }
    }

    /// Calculates total day sleep (7am-7pm) and night sleep (7pm-7am) for a given date range
    static func dayNightSleepBreakdown(_ activities: [Activity]) -> (dayMinutes: Double, nightMinutes: Double) {
        let sleepActivities = activities.filter { $0.kind == .sleep && $0.endTimestamp != nil }
        var dayMinutes: Double = 0
        var nightMinutes: Double = 0

        for activity in sleepActivities {
            guard let end = activity.endTimestamp else { continue }
            let slices = sliceSleepByDayNight(start: activity.timestamp, end: end)
            dayMinutes += slices.dayMinutes
            nightMinutes += slices.nightMinutes
        }

        return (dayMinutes, nightMinutes)
    }

    /// Helper to slice a sleep period into day and night portions
    private static func sliceSleepByDayNight(start: Date, end: Date) -> (dayMinutes: Double, nightMinutes: Double) {
        let calendar = Calendar.current
        var current = start
        var dayMinutes: Double = 0
        var nightMinutes: Double = 0

        while current < end {
            let hour = calendar.component(.hour, from: current)
            let isNight = hour >= 19 || hour < 7

            // Find next boundary (7am or 7pm)
            var nextBoundary: Date
            if hour >= 19 {
                // Next boundary is 7am next day
                nextBoundary = calendar.startOfDay(for: current).addingTimeInterval(24 * 60 * 60 + 7 * 60 * 60)
            } else if hour < 7 {
                // Next boundary is 7am same day
                nextBoundary = calendar.startOfDay(for: current).addingTimeInterval(7 * 60 * 60)
            } else {
                // Next boundary is 7pm same day
                nextBoundary = calendar.startOfDay(for: current).addingTimeInterval(19 * 60 * 60)
            }

            let sliceEnd = min(nextBoundary, end)
            let sliceDuration = sliceEnd.timeIntervalSince(current) / 60

            if isNight {
                nightMinutes += sliceDuration
            } else {
                dayMinutes += sliceDuration
            }

            current = sliceEnd
        }

        return (dayMinutes, nightMinutes)
    }

    /// Calculates average sleep per day for a set of activities (improved version)
    static func sleepTrendData(_ durations: [PlotDuration]) -> [(date: Date, totalMinutes: Double)] {
        let groupedByDay = Dictionary(grouping: durations) {
            Calendar.current.startOfDay(for: $0.start)
        }

        return groupedByDay.map { (date, durations) in
            let totalMinutes = durations.reduce(0.0) { $0 + $1.end.timeIntervalSince($1.start) / 60 }
            return (date: date, totalMinutes: totalMinutes)
        }.sorted { $0.date < $1.date }
    }
}

// MARK: - Dashboard & Trends Helpers

/// Represents a trend comparison between two periods
struct TrendComparison {
    var currentValue: Double
    var previousValue: Double
    var percentageChange: Double
    var trend: TrendDirection

    enum TrendDirection {
        case up, down, stable

        var systemImage: String {
            switch self {
            case .up: return "arrow.up"
            case .down: return "arrow.down"
            case .stable: return "minus"
            }
        }

        var accessibilityLabel: String {
            switch self {
            case .up: return "increased"
            case .down: return "decreased"
            case .stable: return "unchanged"
            }
        }
    }
}

/// Represents a highlight or notable pattern
struct ActivityHighlight: Identifiable {
    var id: UUID = UUID()
    var title: String
    var description: String
    var icon: String
    var color: Color
    var priority: Int  // Lower is more important
}

/// Represents activity data by hour for heat maps
struct HourlyActivityData: Identifiable {
    var hour: Int
    var dayOfWeek: Int  // 1 = Sunday, 7 = Saturday
    var count: Int
    var kind: ActivityKind?
    var id: String { "\(dayOfWeek)-\(hour)" }
}

/// Daily totals for all activity types (for dashboard overview)
struct DailyActivitySummary: Identifiable {
    var date: Date
    var sleepMinutes: Double
    var milkAmount: Int
    var feedingCount: Int
    var diaperCount: Int
    var id: Date { date }
}

import SwiftUI

extension DataController {
    // MARK: - Trend Calculations

    /// Compares current period value vs previous period value
    static func calculateTrend(currentValue: Double, previousValue: Double) -> TrendComparison {
        guard previousValue > 0 else {
            return TrendComparison(
                currentValue: currentValue,
                previousValue: previousValue,
                percentageChange: 0,
                trend: .stable
            )
        }

        let change = ((currentValue - previousValue) / previousValue) * 100
        let trend: TrendComparison.TrendDirection

        if abs(change) < 5 {
            trend = .stable
        } else if change > 0 {
            trend = .up
        } else {
            trend = .down
        }

        return TrendComparison(
            currentValue: currentValue,
            previousValue: previousValue,
            percentageChange: change,
            trend: trend
        )
    }

    /// Calculate sleep trend comparing this week to last week
    static func sleepTrend(_ activities: [Activity]) -> TrendComparison {
        let now = Date()
        let oneWeekAgo = now.addingTimeInterval(-7 * 24 * 60 * 60)
        let twoWeeksAgo = now.addingTimeInterval(-14 * 24 * 60 * 60)

        let currentWeekActivities = activities.filter { $0.kind == .sleep && $0.timestamp >= oneWeekAgo && $0.timestamp <= now }
        let previousWeekActivities = activities.filter { $0.kind == .sleep && $0.timestamp >= twoWeeksAgo && $0.timestamp < oneWeekAgo }

        let currentSleepData = sliceDataToPlot(sleepActivities: currentWeekActivities)
        let previousSleepData = sliceDataToPlot(sleepActivities: previousWeekActivities)

        let currentAvg = averageDurationPerDay(currentSleepData) / 60  // in minutes
        let previousAvg = averageDurationPerDay(previousSleepData) / 60

        return calculateTrend(currentValue: currentAvg, previousValue: previousAvg)
    }

    /// Calculate milk intake trend comparing this week to last week
    static func milkTrend(_ activities: [Activity]) -> TrendComparison {
        let now = Date()
        let oneWeekAgo = now.addingTimeInterval(-7 * 24 * 60 * 60)
        let twoWeeksAgo = now.addingTimeInterval(-14 * 24 * 60 * 60)

        let currentWeekActivities = activities.filter { $0.kind == .milk && $0.timestamp >= oneWeekAgo && $0.timestamp <= now }
        let previousWeekActivities = activities.filter { $0.kind == .milk && $0.timestamp >= twoWeeksAgo && $0.timestamp < oneWeekAgo }

        let currentAvg = averageDailyMilkIntake(currentWeekActivities)
        let previousAvg = averageDailyMilkIntake(previousWeekActivities)

        return calculateTrend(currentValue: currentAvg, previousValue: previousAvg)
    }

    /// Calculate diaper trend comparing this week to last week
    static func diaperTrend(_ activities: [Activity]) -> TrendComparison {
        let now = Date()
        let oneWeekAgo = now.addingTimeInterval(-7 * 24 * 60 * 60)
        let twoWeeksAgo = now.addingTimeInterval(-14 * 24 * 60 * 60)

        let currentWeekActivities = activities.filter {
            ($0.kind == .wetDiaper || $0.kind == .dirtyDiaper) && $0.timestamp >= oneWeekAgo && $0.timestamp <= now
        }
        let previousWeekActivities = activities.filter {
            ($0.kind == .wetDiaper || $0.kind == .dirtyDiaper) && $0.timestamp >= twoWeeksAgo && $0.timestamp < oneWeekAgo
        }

        let currentAvg = averageDiapersPerDay(currentWeekActivities)
        let previousAvg = averageDiapersPerDay(previousWeekActivities)

        return calculateTrend(currentValue: currentAvg, previousValue: previousAvg)
    }

    // MARK: - Highlights Detection

    /// Generates highlights/notable patterns from activity data
    static func generateHighlights(_ activities: [Activity]) -> [ActivityHighlight] {
        var highlights: [ActivityHighlight] = []

        // Check for longest sleep stretch
        if let longestSleep = longestSleepStretch(activities) {
            if longestSleep.durationMinutes >= 240 {  // 4+ hours
                highlights.append(ActivityHighlight(
                    title: "Great Sleep Stretch!",
                    description: "Longest sleep was \(formatMinutesShort(longestSleep.durationMinutes))",
                    icon: "star.fill",
                    color: .yellow,
                    priority: 1
                ))
            }
        }

        // Check milk intake consistency
        let milkData = milkDataByDay(activities)
        if milkData.count >= 3 {
            let amounts = milkData.map { Double($0.totalAmount) }
            let avg = amounts.mean()
            let variance = amounts.map { pow($0 - avg, 2) }.mean()
            let stdDev = sqrt(variance)
            let coefficientOfVariation = avg > 0 ? stdDev / avg : 0

            if coefficientOfVariation < 0.2 && avg > 0 {
                highlights.append(ActivityHighlight(
                    title: "Consistent Feeding",
                    description: "Milk intake has been very consistent",
                    icon: "checkmark.circle.fill",
                    color: .green,
                    priority: 2
                ))
            }
        }

        // Check for good diaper output
        let diaperData = diaperDataByDay(activities)
        if let todayDiapers = diaperData.last, todayDiapers.wetCount >= 6 {
            highlights.append(ActivityHighlight(
                title: "Good Hydration",
                description: "\(todayDiapers.wetCount) wet diapers today",
                icon: "drop.fill",
                color: .cyan,
                priority: 3
            ))
        }

        // Check sleep trend
        let sleepTrendResult = sleepTrend(activities)
        if sleepTrendResult.trend == .up && sleepTrendResult.percentageChange > 10 {
            highlights.append(ActivityHighlight(
                title: "Sleep Improving",
                description: "Sleep is up \(Int(sleepTrendResult.percentageChange))% from last week",
                icon: "arrow.up.circle.fill",
                color: .indigo,
                priority: 2
            ))
        }

        return highlights.sorted { $0.priority < $1.priority }
    }

    private static func formatMinutesShort(_ minutes: Double) -> String {
        let hours = Int(minutes) / 60
        let mins = Int(minutes) % 60
        if hours > 0 {
            return "\(hours)h \(mins)m"
        } else {
            return "\(mins)m"
        }
    }

    // MARK: - Heat Map Data

    /// Groups activities by hour and day of week for heat map visualization
    static func activityHeatMapData(_ activities: [Activity], kind: ActivityKind? = nil) -> [HourlyActivityData] {
        let filtered: [Activity]
        if let kind = kind {
            filtered = activities.filter { $0.kind == kind }
        } else {
            filtered = activities
        }

        var data: [String: Int] = [:]

        // Initialize all cells to 0
        for day in 1...7 {
            for hour in 0..<24 {
                data["\(day)-\(hour)"] = 0
            }
        }

        // Count activities
        for activity in filtered {
            let hour = Calendar.current.component(.hour, from: activity.timestamp)
            let dayOfWeek = Calendar.current.component(.weekday, from: activity.timestamp)
            let key = "\(dayOfWeek)-\(hour)"
            data[key, default: 0] += 1
        }

        // Convert to array
        return data.map { (key, count) in
            let parts = key.split(separator: "-")
            let day = Int(parts[0]) ?? 1
            let hour = Int(parts[1]) ?? 0
            return HourlyActivityData(hour: hour, dayOfWeek: day, count: count, kind: kind)
        }.sorted { ($0.dayOfWeek, $0.hour) < ($1.dayOfWeek, $1.hour) }
    }

    // MARK: - Dashboard Summary

    /// Creates daily summaries for all activity types
    static func dailyActivitySummaries(_ activities: [Activity]) -> [DailyActivitySummary] {
        let calendar = Calendar.current

        // Group all activities by day
        let groupedByDay = Dictionary(grouping: activities) {
            calendar.startOfDay(for: $0.timestamp)
        }

        return groupedByDay.map { (date, dayActivities) in
            // Sleep: sum durations
            let sleepActivities = dayActivities.filter { $0.kind == .sleep && $0.endTimestamp != nil }
            let sleepMinutes = sleepActivities.reduce(0.0) { total, activity in
                guard let end = activity.endTimestamp else { return total }
                return total + end.timeIntervalSince(activity.timestamp) / 60
            }

            // Milk: sum amounts
            let milkActivities = dayActivities.filter { $0.kind == .milk }
            let milkAmount = milkActivities.compactMap { $0.amount }.reduce(0, +)
            let feedingCount = milkActivities.count

            // Diapers: count
            let diaperCount = dayActivities.filter { $0.kind == .wetDiaper || $0.kind == .dirtyDiaper }.count

            return DailyActivitySummary(
                date: date,
                sleepMinutes: sleepMinutes,
                milkAmount: milkAmount,
                feedingCount: feedingCount,
                diaperCount: diaperCount
            )
        }.sorted { $0.date < $1.date }
    }

    /// Gets today's summary
    static func todaySummary(_ activities: [Activity]) -> DailyActivitySummary {
        let today = Calendar.current.startOfDay(for: Date())
        let todayActivities = activities.filter { Calendar.current.startOfDay(for: $0.timestamp) == today }

        let summaries = dailyActivitySummaries(todayActivities)
        return summaries.first ?? DailyActivitySummary(
            date: today,
            sleepMinutes: 0,
            milkAmount: 0,
            feedingCount: 0,
            diaperCount: 0
        )
    }
}

// MARK: - Tummy Time Analytics Helpers

struct DailyTummyTimeData: Identifiable {
    var date: Date
    var totalMinutes: Double
    var sessionCount: Int
    var id: Date { date }
}

extension DataController {
    /// Groups tummy time activities by day and calculates totals
    static func tummyTimeDataByDay(_ activities: [Activity]) -> [DailyTummyTimeData] {
        let tummyTimeActivities = activities.filter { $0.kind == .tummyTime && $0.endTimestamp != nil }
        guard !tummyTimeActivities.isEmpty else { return [] }

        let groupedByDay = Dictionary(grouping: tummyTimeActivities) {
            Calendar.current.startOfDay(for: $0.timestamp)
        }

        return groupedByDay.map { (date, activities) in
            let totalMinutes = activities.reduce(0.0) { total, activity in
                guard let end = activity.endTimestamp else { return total }
                return total + end.timeIntervalSince(activity.timestamp) / 60
            }
            return DailyTummyTimeData(
                date: date,
                totalMinutes: totalMinutes,
                sessionCount: activities.count
            )
        }.sorted { $0.date < $1.date }
    }

    /// Average tummy time per day in minutes
    static func averageTummyTimePerDay(_ activities: [Activity]) -> Double {
        let dailyData = tummyTimeDataByDay(activities)
        guard !dailyData.isEmpty else { return 0 }
        return dailyData.map { $0.totalMinutes }.mean()
    }
}

// MARK: - Solid Food Analytics Helpers

struct DailySolidFoodData: Identifiable {
    var date: Date
    var mealCount: Int
    var foods: [String]
    var id: Date { date }
}

extension DataController {
    /// Groups solid food activities by day
    static func solidFoodDataByDay(_ activities: [Activity]) -> [DailySolidFoodData] {
        let foodActivities = activities.filter { $0.kind == .solidFood }
        guard !foodActivities.isEmpty else { return [] }

        let groupedByDay = Dictionary(grouping: foodActivities) {
            Calendar.current.startOfDay(for: $0.timestamp)
        }

        return groupedByDay.map { (date, activities) in
            let foods = activities.compactMap { $0.foodType }.filter { !$0.isEmpty }
            return DailySolidFoodData(
                date: date,
                mealCount: activities.count,
                foods: foods
            )
        }.sorted { $0.date < $1.date }
    }

    /// Returns unique foods introduced
    static func uniqueFoodsIntroduced(_ activities: [Activity]) -> [String] {
        let foodActivities = activities.filter { $0.kind == .solidFood }
        let foods = foodActivities.compactMap { $0.foodType }.filter { !$0.isEmpty }
        return Array(Set(foods)).sorted()
    }

    /// Returns foods that had reactions
    static func foodsWithReactions(_ activities: [Activity]) -> [String] {
        let foodActivities = activities.filter { $0.kind == .solidFood }
        let foodsWithReaction = foodActivities
            .filter { $0.reactions != nil && !($0.reactions?.isEmpty ?? true) }
            .compactMap { $0.foodType }
            .filter { !$0.isEmpty }
        return Array(Set(foodsWithReaction)).sorted()
    }
}

// MARK: - Medicine Analytics Helpers

struct DailyMedicineData: Identifiable {
    var date: Date
    var doseCount: Int
    var medicines: [String]
    var id: Date { date }
}

extension DataController {
    /// Groups medicine activities by day
    static func medicineDataByDay(_ activities: [Activity]) -> [DailyMedicineData] {
        let medicineActivities = activities.filter { $0.kind == .medicine }
        guard !medicineActivities.isEmpty else { return [] }

        let groupedByDay = Dictionary(grouping: medicineActivities) {
            Calendar.current.startOfDay(for: $0.timestamp)
        }

        return groupedByDay.map { (date, activities) in
            let medicines = activities.compactMap { $0.medicineName }.filter { !$0.isEmpty }
            return DailyMedicineData(
                date: date,
                doseCount: activities.count,
                medicines: medicines
            )
        }.sorted { $0.date < $1.date }
    }

    /// Returns unique medicines
    static func uniqueMedicines(_ activities: [Activity]) -> [String] {
        let medicineActivities = activities.filter { $0.kind == .medicine }
        let medicines = medicineActivities.compactMap { $0.medicineName }.filter { !$0.isEmpty }
        return Array(Set(medicines)).sorted()
    }
}
