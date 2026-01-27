//
//  BabyActivityTests.swift
//  BabyActivityTests
//
//  Created by Zhihao Cui on 19/12/2024.
//

import Testing
import Foundation
@testable import BabyActivity

// MARK: - DataController Tests

@MainActor
struct DataControllerTests {

    // MARK: - sliceDataToPlot Tests

    @Test func sliceDataToPlot_singleDayActivity_returnsOneSlice() {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let start = startOfDay.addingTimeInterval(2 * 60 * 60) // 2 AM
        let end = startOfDay.addingTimeInterval(4 * 60 * 60) // 4 AM

        let activity = Activity(kind: .sleep, timestamp: start, endTimestamp: end)
        let result = DataController.sliceDataToPlot(sleepActivities: [activity])

        #expect(result.count == 1)
        #expect(result[0].start == start)
        #expect(result[0].end == end)
    }

    @Test func sliceDataToPlot_crossMidnightActivity_returnsTwoSlices() {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let start = startOfDay.addingTimeInterval(23 * 60 * 60) // 11 PM
        let end = startOfDay.addingTimeInterval(26 * 60 * 60) // 2 AM next day

        let activity = Activity(kind: .sleep, timestamp: start, endTimestamp: end)
        let result = DataController.sliceDataToPlot(sleepActivities: [activity])

        #expect(result.count == 2)
        // First slice: from 11 PM to just before midnight
        #expect(result[0].start == start)
        // Second slice: from midnight to 2 AM
        #expect(calendar.isDate(result[1].start, inSameDayAs: end))
        #expect(result[1].end == end)
    }

    @Test func sliceDataToPlot_emptyInput_returnsEmpty() {
        let result = DataController.sliceDataToPlot(sleepActivities: [])
        #expect(result.isEmpty)
    }

    @Test func sliceDataToPlot_activityWithNoEndTime_treatsSameAsStart() {
        let start = Date()
        let activity = Activity(kind: .sleep, timestamp: start, endTimestamp: nil, amount: nil)
        let result = DataController.sliceDataToPlot(sleepActivities: [activity])

        #expect(result.count == 1)
        #expect(result[0].start == start)
        #expect(result[0].end == start)
    }

    // MARK: - averageDurationPerDay Tests

    @Test func averageDurationPerDay_singleDay_returnsCorrectAverage() {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())

        let durations = [
            PlotDuration(start: startOfDay.addingTimeInterval(0), end: startOfDay.addingTimeInterval(3600), id: UUID()), // 1 hour
            PlotDuration(start: startOfDay.addingTimeInterval(7200), end: startOfDay.addingTimeInterval(10800), id: UUID()) // 1 hour
        ]

        let result = DataController.averageDurationPerDay(durations)

        // Both durations are on the same day, so total is 2 hours (7200 seconds)
        #expect(result == 7200)
    }

    @Test func averageDurationPerDay_multipleDays_returnsCorrectAverage() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        let durations = [
            // Today: 2 hours total
            PlotDuration(start: today.addingTimeInterval(0), end: today.addingTimeInterval(7200), id: UUID()),
            // Yesterday: 4 hours total
            PlotDuration(start: yesterday.addingTimeInterval(0), end: yesterday.addingTimeInterval(14400), id: UUID())
        ]

        let result = DataController.averageDurationPerDay(durations)

        // Average: (7200 + 14400) / 2 = 10800 seconds (3 hours)
        #expect(result == 10800)
    }

    @Test func averageDurationPerDay_emptyInput_returnsZero() {
        let result = DataController.averageDurationPerDay([])
        #expect(result == 0)
    }

    @Test func averageDurationPerDay_differentMonths_groupsCorrectly() {
        let calendar = Calendar.current
        // Create dates on the same day number but different months
        var jan15Components = DateComponents()
        jan15Components.year = 2024
        jan15Components.month = 1
        jan15Components.day = 15
        jan15Components.hour = 0
        let jan15 = calendar.date(from: jan15Components)!

        var feb15Components = DateComponents()
        feb15Components.year = 2024
        feb15Components.month = 2
        feb15Components.day = 15
        feb15Components.hour = 0
        let feb15 = calendar.date(from: feb15Components)!

        let durations = [
            // Jan 15: 1 hour
            PlotDuration(start: jan15, end: jan15.addingTimeInterval(3600), id: UUID()),
            // Feb 15: 3 hours
            PlotDuration(start: feb15, end: feb15.addingTimeInterval(10800), id: UUID())
        ]

        let result = DataController.averageDurationPerDay(durations)

        // Should be grouped separately: (3600 + 10800) / 2 = 7200
        #expect(result == 7200)
    }

    // MARK: - Array.mean() Tests

    @Test func mean_nonEmptyArray_returnsCorrectMean() {
        let values: [Double] = [2.0, 4.0, 6.0]
        #expect(values.mean() == 4.0)
    }

    @Test func mean_singleElement_returnsThatElement() {
        let values: [Double] = [42.0]
        #expect(values.mean() == 42.0)
    }

    @Test func mean_emptyArray_returnsZero() {
        let values: [Double] = []
        #expect(values.mean() == 0)
    }

    @Test func mean_floatArray_returnsCorrectMean() {
        let values: [Float] = [1.0, 2.0, 3.0, 4.0]
        #expect(values.mean() == 2.5)
    }
}

// MARK: - Activity Model Tests

struct ActivityModelTests {

    // MARK: - Initialization Tests

    @Test func activity_sleepInitialization_setsCorrectProperties() {
        let start = Date()
        let end = Date().addingTimeInterval(3600)
        let activity = Activity(kind: .sleep, timestamp: start, endTimestamp: end)

        #expect(activity.kind == .sleep)
        #expect(activity.timestamp == start)
        #expect(activity.endTimestamp == end)
        #expect(activity.amount == nil)
    }

    @Test func activity_milkInitialization_setsCorrectProperties() {
        let start = Date()
        let end = Date().addingTimeInterval(1800)
        let activity = Activity(kind: .milk, timestamp: start, endTimestamp: end, amount: 120)

        #expect(activity.kind == .milk)
        #expect(activity.timestamp == start)
        #expect(activity.endTimestamp == end)
        #expect(activity.amount == 120)
    }

    @Test func activity_diaperInitialization_setsCorrectProperties() {
        let timestamp = Date()
        let wetDiaper = Activity(kind: .wetDiaper, timestamp: timestamp)
        let dirtyDiaper = Activity(kind: .dirtyDiaper, timestamp: timestamp)

        #expect(wetDiaper.kind == .wetDiaper)
        #expect(wetDiaper.endTimestamp == nil)
        #expect(wetDiaper.amount == nil)

        #expect(dirtyDiaper.kind == .dirtyDiaper)
        #expect(dirtyDiaper.endTimestamp == nil)
        #expect(dirtyDiaper.amount == nil)
    }

    // MARK: - Validation Tests

    @Test func isValidTimeRange_endAfterStart_returnsTrue() {
        let activity = Activity(kind: .sleep, timestamp: Date(), endTimestamp: Date().addingTimeInterval(3600))
        #expect(activity.isValidTimeRange == true)
    }

    @Test func isValidTimeRange_endBeforeStart_returnsFalse() {
        let activity = Activity(kind: .sleep, timestamp: Date(), endTimestamp: Date().addingTimeInterval(-3600))
        #expect(activity.isValidTimeRange == false)
    }

    @Test func isValidTimeRange_endEqualsStart_returnsFalse() {
        let now = Date()
        let activity = Activity(kind: .sleep, timestamp: now, endTimestamp: now)
        #expect(activity.isValidTimeRange == false)
    }

    @Test func isValidTimeRange_noEndTimestamp_returnsTrue() {
        let activity = Activity(kind: .wetDiaper, timestamp: Date())
        #expect(activity.isValidTimeRange == true)
    }

    @Test func isValidMilkAmount_validRange_returnsTrue() {
        let activity = Activity(kind: .milk, timestamp: Date(), endTimestamp: Date().addingTimeInterval(1800), amount: 120)
        #expect(activity.isValidMilkAmount == true)
    }

    @Test func isValidMilkAmount_zeroAmount_returnsTrue() {
        let activity = Activity(kind: .milk, timestamp: Date(), endTimestamp: Date().addingTimeInterval(1800), amount: 0)
        #expect(activity.isValidMilkAmount == true)
    }

    @Test func isValidMilkAmount_maxAmount_returnsTrue() {
        let activity = Activity(kind: .milk, timestamp: Date(), endTimestamp: Date().addingTimeInterval(1800), amount: 500)
        #expect(activity.isValidMilkAmount == true)
    }

    @Test func isValidMilkAmount_exceedsMax_returnsFalse() {
        let activity = Activity(kind: .milk, timestamp: Date(), endTimestamp: Date().addingTimeInterval(1800), amount: 501)
        #expect(activity.isValidMilkAmount == false)
    }

    @Test func isValidMilkAmount_negativeAmount_returnsFalse() {
        let activity = Activity(kind: .milk, timestamp: Date(), endTimestamp: Date().addingTimeInterval(1800), amount: -10)
        #expect(activity.isValidMilkAmount == false)
    }

    @Test func isValidMilkAmount_nonMilkActivity_alwaysTrue() {
        let activity = Activity(kind: .sleep, timestamp: Date(), endTimestamp: Date().addingTimeInterval(3600))
        #expect(activity.isValidMilkAmount == true)
    }

    @Test func isValidMilkAmount_nilAmount_returnsTrue() {
        let activity = Activity(kind: .milk, timestamp: Date(), endTimestamp: Date().addingTimeInterval(1800), amount: nil)
        #expect(activity.isValidMilkAmount == true)
    }

    @Test func isValid_validActivity_returnsTrue() {
        let activity = Activity(kind: .milk, timestamp: Date(), endTimestamp: Date().addingTimeInterval(1800), amount: 100)
        #expect(activity.isValid == true)
    }

    @Test func isValid_invalidTimeRange_returnsFalse() {
        let activity = Activity(kind: .sleep, timestamp: Date(), endTimestamp: Date().addingTimeInterval(-1000))
        #expect(activity.isValid == false)
    }

    @Test func isValid_invalidMilkAmount_returnsFalse() {
        let activity = Activity(kind: .milk, timestamp: Date(), endTimestamp: Date().addingTimeInterval(1800), amount: 1000)
        #expect(activity.isValid == false)
    }

    @Test func validationErrors_validActivity_returnsEmpty() {
        let activity = Activity(kind: .sleep, timestamp: Date(), endTimestamp: Date().addingTimeInterval(3600))
        #expect(activity.validationErrors.isEmpty)
    }

    @Test func validationErrors_invalidTimeRange_returnsError() {
        let activity = Activity(kind: .sleep, timestamp: Date(), endTimestamp: Date().addingTimeInterval(-1000))
        let errors = activity.validationErrors

        #expect(errors.count == 1)
        #expect(errors.contains("End time must be after start time"))
    }

    @Test func validationErrors_invalidMilkAmount_returnsError() {
        let activity = Activity(kind: .milk, timestamp: Date(), endTimestamp: Date().addingTimeInterval(1800), amount: 600)
        let errors = activity.validationErrors

        #expect(errors.count == 1)
        #expect(errors.contains("Milk amount must be between 0 and 500ml"))
    }

    @Test func validationErrors_multipleErrors_returnsAll() {
        let activity = Activity(kind: .milk, timestamp: Date(), endTimestamp: Date().addingTimeInterval(-1000), amount: 600)
        let errors = activity.validationErrors

        #expect(errors.count == 2)
        #expect(errors.contains("End time must be after start time"))
        #expect(errors.contains("Milk amount must be between 0 and 500ml"))
    }

    // MARK: - Display Tests

    @Test func shortDisplay_sleep_showsDuration() {
        let activity = Activity(kind: .sleep, timestamp: Date(), endTimestamp: Date().addingTimeInterval(5400)) // 1.5 hours
        let display = activity.shortDisplay

        #expect(display.contains("Sleep"))
        #expect(display.contains("1") || display.contains("hr") || display.contains("h"))
    }

    @Test func shortDisplay_milk_showsAmount() {
        let activity = Activity(kind: .milk, timestamp: Date(), endTimestamp: Date().addingTimeInterval(1800), amount: 150)
        let display = activity.shortDisplay

        #expect(display == "Milk 150ml")
    }

    @Test func shortDisplay_wetDiaper_showsCorrectText() {
        let activity = Activity(kind: .wetDiaper, timestamp: Date())
        #expect(activity.shortDisplay == "Wet diaper")
    }

    @Test func shortDisplay_dirtyDiaper_showsCorrectText() {
        let activity = Activity(kind: .dirtyDiaper, timestamp: Date())
        #expect(activity.shortDisplay == "Dirty diaper")
    }

    // MARK: - Image Tests

    @Test func image_sleep_returnsZzz() {
        let activity = Activity(kind: .sleep, timestamp: Date(), endTimestamp: Date().addingTimeInterval(3600))
        #expect(activity.image == "zzz")
    }

    @Test func image_milk_returnsCupAndSaucer() {
        let activity = Activity(kind: .milk, timestamp: Date(), endTimestamp: Date().addingTimeInterval(1800), amount: 100)
        #expect(activity.image == "cup.and.saucer.fill")
    }

    @Test func image_wetDiaper_returnsToilet() {
        let activity = Activity(kind: .wetDiaper, timestamp: Date())
        #expect(activity.image == "toilet")
    }

    @Test func image_dirtyDiaper_returnsTornado() {
        let activity = Activity(kind: .dirtyDiaper, timestamp: Date())
        #expect(activity.image == "tornado")
    }
}

// MARK: - ActivityKind Tests

struct ActivityKindTests {

    @Test func description_sleep_returnsCorrectString() {
        #expect(ActivityKind.sleep.description == "sleep")
    }

    @Test func description_milk_returnsCorrectString() {
        #expect(ActivityKind.milk.description == "milk")
    }

    @Test func description_wetDiaper_returnsCorrectString() {
        #expect(ActivityKind.wetDiaper.description == "wet diaper")
    }

    @Test func description_dirtyDiaper_returnsCorrectString() {
        #expect(ActivityKind.dirtyDiaper.description == "dirty diaper")
    }

    @Test func rawValue_allCases_matchExpected() {
        #expect(ActivityKind.sleep.rawValue == "sleep")
        #expect(ActivityKind.milk.rawValue == "milk")
        #expect(ActivityKind.wetDiaper.rawValue == "wetDiaper")
        #expect(ActivityKind.dirtyDiaper.rawValue == "dirtyDiaper")
    }
}

// MARK: - Milk Analytics Tests

@MainActor
struct MilkAnalyticsTests {

    // MARK: - milkDataByDay Tests

    @Test func milkDataByDay_singleDayMultipleFeedings_groupsCorrectly() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let activities = [
            Activity(kind: .milk, timestamp: today.addingTimeInterval(3600), endTimestamp: today.addingTimeInterval(4600), amount: 100),
            Activity(kind: .milk, timestamp: today.addingTimeInterval(7200), endTimestamp: today.addingTimeInterval(8200), amount: 150),
            Activity(kind: .milk, timestamp: today.addingTimeInterval(14400), endTimestamp: today.addingTimeInterval(15400), amount: 120)
        ]

        let result = DataController.milkDataByDay(activities)

        #expect(result.count == 1)
        #expect(result[0].totalAmount == 370)
        #expect(result[0].feedingCount == 3)
        #expect(result[0].averagePerFeeding == 370.0 / 3.0)
    }

    @Test func milkDataByDay_multipleDays_groupsSeparately() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        let activities = [
            Activity(kind: .milk, timestamp: today.addingTimeInterval(3600), endTimestamp: today.addingTimeInterval(4600), amount: 100),
            Activity(kind: .milk, timestamp: yesterday.addingTimeInterval(3600), endTimestamp: yesterday.addingTimeInterval(4600), amount: 200)
        ]

        let result = DataController.milkDataByDay(activities)

        #expect(result.count == 2)
        // Results are sorted by date
        #expect(result[0].totalAmount == 200) // yesterday
        #expect(result[1].totalAmount == 100) // today
    }

    @Test func milkDataByDay_emptyInput_returnsEmpty() {
        let result = DataController.milkDataByDay([])
        #expect(result.isEmpty)
    }

    @Test func milkDataByDay_nonMilkActivities_filtersCorrectly() {
        let today = Calendar.current.startOfDay(for: Date())
        let activities = [
            Activity(kind: .sleep, timestamp: today, endTimestamp: today.addingTimeInterval(3600)),
            Activity(kind: .wetDiaper, timestamp: today)
        ]

        let result = DataController.milkDataByDay(activities)
        #expect(result.isEmpty)
    }

    @Test func milkDataByDay_nilAmounts_treatsAsZero() {
        let today = Calendar.current.startOfDay(for: Date())
        let activities = [
            Activity(kind: .milk, timestamp: today.addingTimeInterval(3600), endTimestamp: today.addingTimeInterval(4600), amount: nil),
            Activity(kind: .milk, timestamp: today.addingTimeInterval(7200), endTimestamp: today.addingTimeInterval(8200), amount: 100)
        ]

        let result = DataController.milkDataByDay(activities)

        #expect(result.count == 1)
        #expect(result[0].totalAmount == 100)
        #expect(result[0].feedingCount == 2)
    }

    // MARK: - averageMilkPerFeeding Tests

    @Test func averageMilkPerFeeding_multipleFeedings_calculatesCorrectly() {
        let today = Calendar.current.startOfDay(for: Date())
        let activities = [
            Activity(kind: .milk, timestamp: today, endTimestamp: today.addingTimeInterval(1800), amount: 100),
            Activity(kind: .milk, timestamp: today.addingTimeInterval(3600), endTimestamp: today.addingTimeInterval(5400), amount: 200),
            Activity(kind: .milk, timestamp: today.addingTimeInterval(7200), endTimestamp: today.addingTimeInterval(9000), amount: 150)
        ]

        let result = DataController.averageMilkPerFeeding(activities)

        #expect(result == 150.0) // (100 + 200 + 150) / 3
    }

    @Test func averageMilkPerFeeding_emptyInput_returnsZero() {
        let result = DataController.averageMilkPerFeeding([])
        #expect(result == 0)
    }

    @Test func averageMilkPerFeeding_noMilkActivities_returnsZero() {
        let activities = [
            Activity(kind: .sleep, timestamp: Date(), endTimestamp: Date().addingTimeInterval(3600))
        ]

        let result = DataController.averageMilkPerFeeding(activities)
        #expect(result == 0)
    }

    // MARK: - averageDailyMilkIntake Tests

    @Test func averageDailyMilkIntake_multipleDays_calculatesCorrectly() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        let activities = [
            // Today: 300ml total
            Activity(kind: .milk, timestamp: today.addingTimeInterval(3600), endTimestamp: today.addingTimeInterval(4600), amount: 100),
            Activity(kind: .milk, timestamp: today.addingTimeInterval(7200), endTimestamp: today.addingTimeInterval(8200), amount: 200),
            // Yesterday: 400ml total
            Activity(kind: .milk, timestamp: yesterday.addingTimeInterval(3600), endTimestamp: yesterday.addingTimeInterval(4600), amount: 400)
        ]

        let result = DataController.averageDailyMilkIntake(activities)

        #expect(result == 350.0) // (300 + 400) / 2
    }

    @Test func averageDailyMilkIntake_emptyInput_returnsZero() {
        let result = DataController.averageDailyMilkIntake([])
        #expect(result == 0)
    }

    // MARK: - feedingIntervals Tests

    @Test func feedingIntervals_multipleFeedings_calculatesCorrectly() {
        let today = Calendar.current.startOfDay(for: Date())
        let activities = [
            Activity(kind: .milk, timestamp: today, endTimestamp: today.addingTimeInterval(1800), amount: 100),
            Activity(kind: .milk, timestamp: today.addingTimeInterval(7200), endTimestamp: today.addingTimeInterval(9000), amount: 100), // 2 hours later
            Activity(kind: .milk, timestamp: today.addingTimeInterval(14400), endTimestamp: today.addingTimeInterval(16200), amount: 100) // 2 hours later
        ]

        let result = DataController.feedingIntervals(activities)

        #expect(result.count == 2)
        #expect(result[0].intervalMinutes == 120.0) // 2 hours = 120 minutes
        #expect(result[1].intervalMinutes == 120.0)
    }

    @Test func feedingIntervals_singleFeeding_returnsEmpty() {
        let today = Calendar.current.startOfDay(for: Date())
        let activities = [
            Activity(kind: .milk, timestamp: today, endTimestamp: today.addingTimeInterval(1800), amount: 100)
        ]

        let result = DataController.feedingIntervals(activities)
        #expect(result.isEmpty)
    }

    @Test func feedingIntervals_emptyInput_returnsEmpty() {
        let result = DataController.feedingIntervals([])
        #expect(result.isEmpty)
    }

    // MARK: - averageFeedingIntervalMinutes Tests

    @Test func averageFeedingIntervalMinutes_multipleFeedings_calculatesCorrectly() {
        let today = Calendar.current.startOfDay(for: Date())
        let activities = [
            Activity(kind: .milk, timestamp: today, endTimestamp: today.addingTimeInterval(1800), amount: 100),
            Activity(kind: .milk, timestamp: today.addingTimeInterval(3600), endTimestamp: today.addingTimeInterval(5400), amount: 100), // 1 hour later
            Activity(kind: .milk, timestamp: today.addingTimeInterval(10800), endTimestamp: today.addingTimeInterval(12600), amount: 100) // 2 hours later
        ]

        let result = DataController.averageFeedingIntervalMinutes(activities)

        #expect(result == 90.0) // (60 + 120) / 2
    }

    @Test func averageFeedingIntervalMinutes_emptyInput_returnsZero() {
        let result = DataController.averageFeedingIntervalMinutes([])
        #expect(result == 0)
    }
}

// MARK: - Diaper Analytics Tests

@MainActor
struct DiaperAnalyticsTests {

    // MARK: - diaperDataByDay Tests

    @Test func diaperDataByDay_mixedDiapers_countsCorrectly() {
        let today = Calendar.current.startOfDay(for: Date())
        let activities = [
            Activity(kind: .wetDiaper, timestamp: today.addingTimeInterval(3600)),
            Activity(kind: .wetDiaper, timestamp: today.addingTimeInterval(7200)),
            Activity(kind: .dirtyDiaper, timestamp: today.addingTimeInterval(10800)),
            Activity(kind: .wetDiaper, timestamp: today.addingTimeInterval(14400))
        ]

        let result = DataController.diaperDataByDay(activities)

        #expect(result.count == 1)
        #expect(result[0].wetCount == 3)
        #expect(result[0].dirtyCount == 1)
        #expect(result[0].totalCount == 4)
    }

    @Test func diaperDataByDay_multipleDays_groupsSeparately() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        let activities = [
            Activity(kind: .wetDiaper, timestamp: today.addingTimeInterval(3600)),
            Activity(kind: .dirtyDiaper, timestamp: today.addingTimeInterval(7200)),
            Activity(kind: .wetDiaper, timestamp: yesterday.addingTimeInterval(3600))
        ]

        let result = DataController.diaperDataByDay(activities)

        #expect(result.count == 2)
        // Results are sorted by date
        #expect(result[0].totalCount == 1) // yesterday
        #expect(result[1].totalCount == 2) // today
    }

    @Test func diaperDataByDay_emptyInput_returnsEmpty() {
        let result = DataController.diaperDataByDay([])
        #expect(result.isEmpty)
    }

    @Test func diaperDataByDay_nonDiaperActivities_filtersCorrectly() {
        let today = Calendar.current.startOfDay(for: Date())
        let activities = [
            Activity(kind: .sleep, timestamp: today, endTimestamp: today.addingTimeInterval(3600)),
            Activity(kind: .milk, timestamp: today, endTimestamp: today.addingTimeInterval(1800), amount: 100)
        ]

        let result = DataController.diaperDataByDay(activities)
        #expect(result.isEmpty)
    }

    // MARK: - diaperDataByHour Tests

    @Test func diaperDataByHour_variousHours_groupsCorrectly() {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = 8
        components.minute = 30
        let hour8 = calendar.date(from: components)!

        components.hour = 14
        let hour14 = calendar.date(from: components)!

        let activities = [
            Activity(kind: .wetDiaper, timestamp: hour8),
            Activity(kind: .wetDiaper, timestamp: hour8.addingTimeInterval(1200)), // still hour 8
            Activity(kind: .dirtyDiaper, timestamp: hour14)
        ]

        let result = DataController.diaperDataByHour(activities)

        #expect(result.count == 24)
        #expect(result[8].wetCount == 2)
        #expect(result[8].dirtyCount == 0)
        #expect(result[14].wetCount == 0)
        #expect(result[14].dirtyCount == 1)
    }

    @Test func diaperDataByHour_emptyInput_returnsEmpty() {
        let result = DataController.diaperDataByHour([])
        #expect(result.isEmpty)
    }

    // MARK: - averageDiapersPerDay Tests

    @Test func averageDiapersPerDay_multipleDays_calculatesCorrectly() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        let activities = [
            // Today: 4 diapers
            Activity(kind: .wetDiaper, timestamp: today.addingTimeInterval(3600)),
            Activity(kind: .wetDiaper, timestamp: today.addingTimeInterval(7200)),
            Activity(kind: .dirtyDiaper, timestamp: today.addingTimeInterval(10800)),
            Activity(kind: .wetDiaper, timestamp: today.addingTimeInterval(14400)),
            // Yesterday: 2 diapers
            Activity(kind: .wetDiaper, timestamp: yesterday.addingTimeInterval(3600)),
            Activity(kind: .dirtyDiaper, timestamp: yesterday.addingTimeInterval(7200))
        ]

        let result = DataController.averageDiapersPerDay(activities)

        #expect(result == 3.0) // (4 + 2) / 2
    }

    @Test func averageDiapersPerDay_emptyInput_returnsZero() {
        let result = DataController.averageDiapersPerDay([])
        #expect(result == 0)
    }
}

// MARK: - Enhanced Sleep Analytics Tests

@MainActor
struct EnhancedSleepAnalyticsTests {

    // MARK: - longestSleepStretch Tests

    @Test func longestSleepStretch_multipleSleeps_findsLongest() {
        let today = Calendar.current.startOfDay(for: Date())
        let activities = [
            Activity(kind: .sleep, timestamp: today.addingTimeInterval(3600), endTimestamp: today.addingTimeInterval(7200)), // 1 hour
            Activity(kind: .sleep, timestamp: today.addingTimeInterval(10800), endTimestamp: today.addingTimeInterval(21600)), // 3 hours (longest)
            Activity(kind: .sleep, timestamp: today.addingTimeInterval(25200), endTimestamp: today.addingTimeInterval(28800)) // 1 hour
        ]

        let result = DataController.longestSleepStretch(activities)

        #expect(result != nil)
        #expect(result!.durationMinutes == 180.0) // 3 hours = 180 minutes
    }

    @Test func longestSleepStretch_emptyInput_returnsNil() {
        let result = DataController.longestSleepStretch([])
        #expect(result == nil)
    }

    @Test func longestSleepStretch_noEndTimestamp_returnsNil() {
        let activities = [
            Activity(kind: .sleep, timestamp: Date())
        ]

        let result = DataController.longestSleepStretch(activities)
        #expect(result == nil)
    }

    @Test func longestSleepStretch_nightSleep_markedCorrectly() {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = 21 // 9 PM (night time)
        components.minute = 0
        let nightStart = calendar.date(from: components)!

        let activities = [
            Activity(kind: .sleep, timestamp: nightStart, endTimestamp: nightStart.addingTimeInterval(7200))
        ]

        let result = DataController.longestSleepStretch(activities)

        #expect(result != nil)
        #expect(result!.isNightSleep == true)
    }

    @Test func longestSleepStretch_daySleep_markedCorrectly() {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = 14 // 2 PM (day time)
        components.minute = 0
        let dayStart = calendar.date(from: components)!

        let activities = [
            Activity(kind: .sleep, timestamp: dayStart, endTimestamp: dayStart.addingTimeInterval(7200))
        ]

        let result = DataController.longestSleepStretch(activities)

        #expect(result != nil)
        #expect(result!.isNightSleep == false)
    }

    // MARK: - dayNightSleepBreakdown Tests

    @Test func dayNightSleepBreakdown_daySleepOnly_calculatesCorrectly() {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = 10 // 10 AM (day time)
        components.minute = 0
        let dayStart = calendar.date(from: components)!

        let activities = [
            Activity(kind: .sleep, timestamp: dayStart, endTimestamp: dayStart.addingTimeInterval(7200)) // 2 hours
        ]

        let result = DataController.dayNightSleepBreakdown(activities)

        #expect(result.dayMinutes == 120.0) // 2 hours
        #expect(result.nightMinutes == 0.0)
    }

    @Test func dayNightSleepBreakdown_nightSleepOnly_calculatesCorrectly() {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = 22 // 10 PM (night time)
        components.minute = 0
        let nightStart = calendar.date(from: components)!

        let activities = [
            Activity(kind: .sleep, timestamp: nightStart, endTimestamp: nightStart.addingTimeInterval(7200)) // 2 hours (stays in night)
        ]

        let result = DataController.dayNightSleepBreakdown(activities)

        #expect(result.dayMinutes == 0.0)
        #expect(result.nightMinutes == 120.0) // 2 hours
    }

    @Test func dayNightSleepBreakdown_emptyInput_returnsZero() {
        let result = DataController.dayNightSleepBreakdown([])

        #expect(result.dayMinutes == 0.0)
        #expect(result.nightMinutes == 0.0)
    }

    @Test func dayNightSleepBreakdown_crossingBoundary_slicesCorrectly() {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = 18 // 6 PM (day time, 1 hour before night)
        components.minute = 0
        let start = calendar.date(from: components)!

        // Sleep from 6 PM to 8 PM (1 hour day, 1 hour night)
        let activities = [
            Activity(kind: .sleep, timestamp: start, endTimestamp: start.addingTimeInterval(7200))
        ]

        let result = DataController.dayNightSleepBreakdown(activities)

        #expect(result.dayMinutes == 60.0) // 1 hour day
        #expect(result.nightMinutes == 60.0) // 1 hour night
    }

    // MARK: - sleepTrendData Tests

    @Test func sleepTrendData_multipleDays_groupsCorrectly() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        let durations = [
            // Today: 2 hours total
            PlotDuration(start: today.addingTimeInterval(3600), end: today.addingTimeInterval(10800), id: UUID()),
            // Yesterday: 3 hours total
            PlotDuration(start: yesterday.addingTimeInterval(3600), end: yesterday.addingTimeInterval(14400), id: UUID())
        ]

        let result = DataController.sleepTrendData(durations)

        #expect(result.count == 2)
        // Results are sorted by date
        #expect(result[0].totalMinutes == 180.0) // yesterday: 3 hours
        #expect(result[1].totalMinutes == 120.0) // today: 2 hours
    }

    @Test func sleepTrendData_sameDayMultipleSleeps_sumsTotals() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let durations = [
            PlotDuration(start: today.addingTimeInterval(3600), end: today.addingTimeInterval(7200), id: UUID()), // 1 hour
            PlotDuration(start: today.addingTimeInterval(10800), end: today.addingTimeInterval(14400), id: UUID()) // 1 hour
        ]

        let result = DataController.sleepTrendData(durations)

        #expect(result.count == 1)
        #expect(result[0].totalMinutes == 120.0) // 2 hours total
    }

    @Test func sleepTrendData_emptyInput_returnsEmpty() {
        let result = DataController.sleepTrendData([])
        #expect(result.isEmpty)
    }
}
