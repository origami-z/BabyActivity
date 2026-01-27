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
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            let container = try ModelContainer(for: Activity.self, configurations: config)
            
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
                Activity(kind: .wetDiaper, timestamp: startOfToday.addingTimeInterval(startingTimeInterval + hourInterval * 19.4))
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
