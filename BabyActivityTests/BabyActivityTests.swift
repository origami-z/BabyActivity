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

    @Test func description_solidFood_returnsCorrectString() {
        #expect(ActivityKind.solidFood.description == "solid food")
    }

    @Test func description_tummyTime_returnsCorrectString() {
        #expect(ActivityKind.tummyTime.description == "tummy time")
    }

    @Test func description_bathTime_returnsCorrectString() {
        #expect(ActivityKind.bathTime.description == "bath time")
    }

    @Test func description_medicine_returnsCorrectString() {
        #expect(ActivityKind.medicine.description == "medicine")
    }

    @Test func rawValue_allCases_matchExpected() {
        #expect(ActivityKind.sleep.rawValue == "sleep")
        #expect(ActivityKind.milk.rawValue == "milk")
        #expect(ActivityKind.wetDiaper.rawValue == "wetDiaper")
        #expect(ActivityKind.dirtyDiaper.rawValue == "dirtyDiaper")
        #expect(ActivityKind.solidFood.rawValue == "solidFood")
        #expect(ActivityKind.tummyTime.rawValue == "tummyTime")
        #expect(ActivityKind.bathTime.rawValue == "bathTime")
        #expect(ActivityKind.medicine.rawValue == "medicine")
    }

    @Test func allCases_containsAllActivityTypes() {
        #expect(ActivityKind.allCases.count == 8)
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

// MARK: - Dashboard & Trends Tests

@MainActor
struct DashboardTrendsTests {

    // MARK: - calculateTrend Tests

    @Test func calculateTrend_increase_returnsUpTrend() {
        let result = DataController.calculateTrend(currentValue: 120, previousValue: 100)

        #expect(result.currentValue == 120)
        #expect(result.previousValue == 100)
        #expect(result.percentageChange == 20.0)
        #expect(result.trend == .up)
    }

    @Test func calculateTrend_decrease_returnsDownTrend() {
        let result = DataController.calculateTrend(currentValue: 80, previousValue: 100)

        #expect(result.currentValue == 80)
        #expect(result.previousValue == 100)
        #expect(result.percentageChange == -20.0)
        #expect(result.trend == .down)
    }

    @Test func calculateTrend_smallChange_returnsStable() {
        let result = DataController.calculateTrend(currentValue: 102, previousValue: 100)

        #expect(result.trend == .stable) // 2% change is < 5% threshold
    }

    @Test func calculateTrend_zeroPreviousValue_returnsStable() {
        let result = DataController.calculateTrend(currentValue: 100, previousValue: 0)

        #expect(result.trend == .stable)
        #expect(result.percentageChange == 0)
    }

    @Test func calculateTrend_bothZero_returnsStable() {
        let result = DataController.calculateTrend(currentValue: 0, previousValue: 0)

        #expect(result.trend == .stable)
    }

    // MARK: - TrendDirection Tests

    @Test func trendDirection_up_hasCorrectProperties() {
        let trend = TrendComparison.TrendDirection.up
        #expect(trend.systemImage == "arrow.up")
        #expect(trend.accessibilityLabel == "increased")
    }

    @Test func trendDirection_down_hasCorrectProperties() {
        let trend = TrendComparison.TrendDirection.down
        #expect(trend.systemImage == "arrow.down")
        #expect(trend.accessibilityLabel == "decreased")
    }

    @Test func trendDirection_stable_hasCorrectProperties() {
        let trend = TrendComparison.TrendDirection.stable
        #expect(trend.systemImage == "minus")
        #expect(trend.accessibilityLabel == "unchanged")
    }

    // MARK: - activityHeatMapData Tests

    @Test func activityHeatMapData_emptyInput_returnsAllZeros() {
        let result = DataController.activityHeatMapData([])

        #expect(result.count == 168) // 7 days * 24 hours
        #expect(result.allSatisfy { $0.count == 0 })
    }

    @Test func activityHeatMapData_singleActivity_countsCorrectly() {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = 10
        components.minute = 0
        let timestamp = calendar.date(from: components)!

        let activities = [Activity(kind: .milk, timestamp: timestamp, endTimestamp: timestamp.addingTimeInterval(1800), amount: 100)]
        let result = DataController.activityHeatMapData(activities)

        let hour10Data = result.filter { $0.hour == 10 }
        let dayOfWeek = calendar.component(.weekday, from: timestamp)
        let matchingCell = hour10Data.first { $0.dayOfWeek == dayOfWeek }

        #expect(matchingCell != nil)
        #expect(matchingCell!.count == 1)
    }

    @Test func activityHeatMapData_filteredByKind_filtersCorrectly() {
        let today = Calendar.current.startOfDay(for: Date())
        let activities = [
            Activity(kind: .milk, timestamp: today.addingTimeInterval(3600), endTimestamp: today.addingTimeInterval(4600), amount: 100),
            Activity(kind: .sleep, timestamp: today.addingTimeInterval(7200), endTimestamp: today.addingTimeInterval(10800)),
            Activity(kind: .wetDiaper, timestamp: today.addingTimeInterval(14400))
        ]

        let milkResult = DataController.activityHeatMapData(activities, kind: .milk)
        let totalMilkCount = milkResult.reduce(0) { $0 + $1.count }

        #expect(totalMilkCount == 1)
    }

    @Test func activityHeatMapData_multipleActivities_countsAll() {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = 8
        components.minute = 0
        let hour8 = calendar.date(from: components)!

        let activities = [
            Activity(kind: .milk, timestamp: hour8, endTimestamp: hour8.addingTimeInterval(1800), amount: 100),
            Activity(kind: .milk, timestamp: hour8.addingTimeInterval(60), endTimestamp: hour8.addingTimeInterval(1860), amount: 100),
            Activity(kind: .milk, timestamp: hour8.addingTimeInterval(120), endTimestamp: hour8.addingTimeInterval(1920), amount: 100)
        ]

        let result = DataController.activityHeatMapData(activities, kind: .milk)
        let totalCount = result.reduce(0) { $0 + $1.count }

        #expect(totalCount == 3)
    }

    // MARK: - dailyActivitySummaries Tests

    @Test func dailyActivitySummaries_emptyInput_returnsEmpty() {
        let result = DataController.dailyActivitySummaries([])
        #expect(result.isEmpty)
    }

    @Test func dailyActivitySummaries_singleDay_aggregatesCorrectly() {
        let today = Calendar.current.startOfDay(for: Date())
        let activities = [
            Activity(kind: .sleep, timestamp: today.addingTimeInterval(3600), endTimestamp: today.addingTimeInterval(7200)), // 1 hour sleep
            Activity(kind: .milk, timestamp: today.addingTimeInterval(10800), endTimestamp: today.addingTimeInterval(12600), amount: 100),
            Activity(kind: .milk, timestamp: today.addingTimeInterval(21600), endTimestamp: today.addingTimeInterval(23400), amount: 150),
            Activity(kind: .wetDiaper, timestamp: today.addingTimeInterval(14400)),
            Activity(kind: .dirtyDiaper, timestamp: today.addingTimeInterval(18000))
        ]

        let result = DataController.dailyActivitySummaries(activities)

        #expect(result.count == 1)
        #expect(result[0].sleepMinutes == 60.0) // 1 hour = 60 minutes
        #expect(result[0].milkAmount == 250) // 100 + 150
        #expect(result[0].feedingCount == 2)
        #expect(result[0].diaperCount == 2)
    }

    @Test func dailyActivitySummaries_multipleDays_groupsSeparately() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        let activities = [
            Activity(kind: .milk, timestamp: today.addingTimeInterval(3600), endTimestamp: today.addingTimeInterval(5400), amount: 100),
            Activity(kind: .milk, timestamp: yesterday.addingTimeInterval(3600), endTimestamp: yesterday.addingTimeInterval(5400), amount: 200)
        ]

        let result = DataController.dailyActivitySummaries(activities)

        #expect(result.count == 2)
        #expect(result[0].milkAmount == 200) // yesterday (sorted first)
        #expect(result[1].milkAmount == 100) // today
    }

    @Test func dailyActivitySummaries_sleepWithNoEnd_treatsAsZeroDuration() {
        let today = Calendar.current.startOfDay(for: Date())
        let activities = [
            Activity(kind: .sleep, timestamp: today.addingTimeInterval(3600), endTimestamp: nil, amount: nil)
        ]

        let result = DataController.dailyActivitySummaries(activities)

        #expect(result.count == 1)
        #expect(result[0].sleepMinutes == 0.0)
    }

    // MARK: - todaySummary Tests

    @Test func todaySummary_noActivitiesToday_returnsZeroSummary() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let activities = [
            Activity(kind: .milk, timestamp: yesterday, endTimestamp: yesterday.addingTimeInterval(1800), amount: 100)
        ]

        let result = DataController.todaySummary(activities)

        #expect(result.sleepMinutes == 0)
        #expect(result.milkAmount == 0)
        #expect(result.feedingCount == 0)
        #expect(result.diaperCount == 0)
    }

    @Test func todaySummary_withTodayActivities_calculatesCorrectly() {
        let today = Calendar.current.startOfDay(for: Date())
        let activities = [
            Activity(kind: .sleep, timestamp: today.addingTimeInterval(3600), endTimestamp: today.addingTimeInterval(10800)), // 2 hours
            Activity(kind: .milk, timestamp: today.addingTimeInterval(14400), endTimestamp: today.addingTimeInterval(16200), amount: 120),
            Activity(kind: .wetDiaper, timestamp: today.addingTimeInterval(18000))
        ]

        let result = DataController.todaySummary(activities)

        #expect(result.sleepMinutes == 120.0) // 2 hours
        #expect(result.milkAmount == 120)
        #expect(result.feedingCount == 1)
        #expect(result.diaperCount == 1)
    }

    @Test func todaySummary_emptyInput_returnsZeroSummary() {
        let result = DataController.todaySummary([])

        #expect(result.sleepMinutes == 0)
        #expect(result.milkAmount == 0)
        #expect(result.feedingCount == 0)
        #expect(result.diaperCount == 0)
    }

    // MARK: - generateHighlights Tests

    @Test func generateHighlights_emptyInput_returnsEmpty() {
        let result = DataController.generateHighlights([])
        #expect(result.isEmpty)
    }

    @Test func generateHighlights_longSleep_includesHighlight() {
        let today = Calendar.current.startOfDay(for: Date())
        let activities = [
            // 5 hour sleep (> 4 hour threshold)
            Activity(kind: .sleep, timestamp: today.addingTimeInterval(3600), endTimestamp: today.addingTimeInterval(21600))
        ]

        let result = DataController.generateHighlights(activities)

        let sleepHighlight = result.first { $0.title.contains("Sleep") }
        #expect(sleepHighlight != nil)
    }

    @Test func generateHighlights_sortsByPriority() {
        let today = Calendar.current.startOfDay(for: Date())
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        let twoDaysAgo = Calendar.current.date(byAdding: .day, value: -2, to: today)!

        let activities = [
            // Long sleep (priority 1)
            Activity(kind: .sleep, timestamp: today.addingTimeInterval(3600), endTimestamp: today.addingTimeInterval(21600)),
            // Wet diapers for hydration highlight
            Activity(kind: .wetDiaper, timestamp: today.addingTimeInterval(3600)),
            Activity(kind: .wetDiaper, timestamp: today.addingTimeInterval(7200)),
            Activity(kind: .wetDiaper, timestamp: today.addingTimeInterval(10800)),
            Activity(kind: .wetDiaper, timestamp: today.addingTimeInterval(14400)),
            Activity(kind: .wetDiaper, timestamp: today.addingTimeInterval(18000)),
            Activity(kind: .wetDiaper, timestamp: today.addingTimeInterval(21600)),
            Activity(kind: .wetDiaper, timestamp: today.addingTimeInterval(25200)),
            // Consistent milk across 3 days
            Activity(kind: .milk, timestamp: today.addingTimeInterval(7200), endTimestamp: today.addingTimeInterval(9000), amount: 100),
            Activity(kind: .milk, timestamp: yesterday.addingTimeInterval(7200), endTimestamp: yesterday.addingTimeInterval(9000), amount: 100),
            Activity(kind: .milk, timestamp: twoDaysAgo.addingTimeInterval(7200), endTimestamp: twoDaysAgo.addingTimeInterval(9000), amount: 100)
        ]

        let result = DataController.generateHighlights(activities)

        if result.count >= 2 {
            // First highlight should have lower priority number (more important)
            #expect(result[0].priority <= result[1].priority)
        }
    }
}

// MARK: - Heat Map Data Structure Tests

struct HeatMapDataTests {

    @Test func hourlyActivityData_idIsUnique() {
        let data1 = HourlyActivityData(hour: 10, dayOfWeek: 1, count: 5, kind: .milk)
        let data2 = HourlyActivityData(hour: 10, dayOfWeek: 2, count: 3, kind: .milk)
        let data3 = HourlyActivityData(hour: 11, dayOfWeek: 1, count: 2, kind: .milk)

        #expect(data1.id != data2.id)
        #expect(data1.id != data3.id)
        #expect(data2.id != data3.id)
    }

    @Test func hourlyActivityData_idFormat() {
        let data = HourlyActivityData(hour: 10, dayOfWeek: 3, count: 5, kind: .milk)
        #expect(data.id == "3-10")
    }
}

// MARK: - Trend Comparison Structure Tests

struct TrendComparisonTests {

    @Test func trendComparison_storesValues() {
        let comparison = TrendComparison(
            currentValue: 150,
            previousValue: 100,
            percentageChange: 50,
            trend: .up
        )

        #expect(comparison.currentValue == 150)
        #expect(comparison.previousValue == 100)
        #expect(comparison.percentageChange == 50)
        #expect(comparison.trend == .up)
    }
}

// MARK: - Daily Activity Summary Structure Tests

struct DailyActivitySummaryTests {

    @Test func dailyActivitySummary_idIsDate() {
        let date = Date()
        let summary = DailyActivitySummary(
            date: date,
            sleepMinutes: 120,
            milkAmount: 500,
            feedingCount: 5,
            diaperCount: 8
        )

        #expect(summary.id == date)
    }

    @Test func dailyActivitySummary_storesAllValues() {
        let date = Date()
        let summary = DailyActivitySummary(
            date: date,
            sleepMinutes: 180,
            milkAmount: 600,
            feedingCount: 6,
            diaperCount: 10
        )

        #expect(summary.sleepMinutes == 180)
        #expect(summary.milkAmount == 600)
        #expect(summary.feedingCount == 6)
        #expect(summary.diaperCount == 10)
    }
}

// MARK: - Phase 4: Extended Activity Types Tests

struct ExtendedActivityTypesTests {

    // MARK: - Solid Food Tests

    @Test func solidFood_initialization_setsCorrectProperties() {
        let timestamp = Date()
        let activity = Activity(kind: .solidFood, timestamp: timestamp, foodType: "Banana puree")

        #expect(activity.kind == .solidFood)
        #expect(activity.timestamp == timestamp)
        #expect(activity.foodType == "Banana puree")
        #expect(activity.reactions == nil)
    }

    @Test func solidFood_withReaction_storesReaction() {
        let activity = Activity(kind: .solidFood, timestamp: Date(), foodType: "Peanut butter", reactions: "Mild rash")

        #expect(activity.foodType == "Peanut butter")
        #expect(activity.reactions == "Mild rash")
    }

    @Test func solidFood_shortDisplay_showsFoodType() {
        let activity = Activity(kind: .solidFood, timestamp: Date(), foodType: "Avocado")
        #expect(activity.shortDisplay == "Food: Avocado")
    }

    @Test func solidFood_shortDisplay_unknownIfEmpty() {
        let activity = Activity(kind: .solidFood, timestamp: Date(), endTimestamp: nil, amount: nil)
        #expect(activity.shortDisplay == "Food: Unknown")
    }

    @Test func solidFood_image_returnsForkKnife() {
        let activity = Activity(kind: .solidFood, timestamp: Date(), foodType: "Carrot")
        #expect(activity.image == "fork.knife")
    }

    // MARK: - Tummy Time Tests

    @Test func tummyTime_initialization_setsCorrectProperties() {
        let start = Date()
        let end = start.addingTimeInterval(900) // 15 minutes
        let activity = Activity(kind: .tummyTime, timestamp: start, endTimestamp: end)

        #expect(activity.kind == .tummyTime)
        #expect(activity.timestamp == start)
        #expect(activity.endTimestamp == end)
    }

    @Test func tummyTime_shortDisplay_showsDuration() {
        let activity = Activity(kind: .tummyTime, timestamp: Date(), endTimestamp: Date().addingTimeInterval(900))
        let display = activity.shortDisplay

        #expect(display.contains("Tummy"))
    }

    @Test func tummyTime_image_returnsFigureChild() {
        let activity = Activity(kind: .tummyTime, timestamp: Date(), endTimestamp: Date().addingTimeInterval(600))
        #expect(activity.image == "figure.child")
    }

    // MARK: - Bath Time Tests

    @Test func bathTime_initialization_setsCorrectProperties() {
        let timestamp = Date()
        let activity = Activity(kind: .bathTime, timestamp: timestamp)

        #expect(activity.kind == .bathTime)
        #expect(activity.timestamp == timestamp)
        #expect(activity.endTimestamp == nil)
    }

    @Test func bathTime_shortDisplay_showsBathTime() {
        let activity = Activity(kind: .bathTime, timestamp: Date())
        #expect(activity.shortDisplay == "Bath time")
    }

    @Test func bathTime_image_returnsBathtub() {
        let activity = Activity(kind: .bathTime, timestamp: Date())
        #expect(activity.image == "bathtub.fill")
    }

    // MARK: - Medicine Tests

    @Test func medicine_initialization_setsCorrectProperties() {
        let timestamp = Date()
        let activity = Activity(kind: .medicine, timestamp: timestamp, medicineName: "Vitamin D", dosage: "1 drop")

        #expect(activity.kind == .medicine)
        #expect(activity.timestamp == timestamp)
        #expect(activity.medicineName == "Vitamin D")
        #expect(activity.dosage == "1 drop")
    }

    @Test func medicine_shortDisplay_showsMedicineName() {
        let activity = Activity(kind: .medicine, timestamp: Date(), medicineName: "Tylenol", dosage: "2.5ml")
        #expect(activity.shortDisplay == "Medicine: Tylenol")
    }

    @Test func medicine_shortDisplay_noName_showsMedicine() {
        let activity = Activity(kind: .medicine, timestamp: Date(), endTimestamp: nil, amount: nil)
        #expect(activity.shortDisplay == "Medicine")
    }

    @Test func medicine_image_returnsCrossCase() {
        let activity = Activity(kind: .medicine, timestamp: Date(), medicineName: "Ibuprofen", dosage: nil)
        #expect(activity.image == "cross.case.fill")
    }
}

// MARK: - Tummy Time Analytics Tests

@MainActor
struct TummyTimeAnalyticsTests {

    @Test func tummyTimeDataByDay_singleDay_groupsCorrectly() {
        let today = Calendar.current.startOfDay(for: Date())
        let activities = [
            Activity(kind: .tummyTime, timestamp: today.addingTimeInterval(3600), endTimestamp: today.addingTimeInterval(4500)), // 15 min
            Activity(kind: .tummyTime, timestamp: today.addingTimeInterval(7200), endTimestamp: today.addingTimeInterval(7800))  // 10 min
        ]

        let result = DataController.tummyTimeDataByDay(activities)

        #expect(result.count == 1)
        #expect(result[0].totalMinutes == 25.0) // 15 + 10 minutes
        #expect(result[0].sessionCount == 2)
    }

    @Test func tummyTimeDataByDay_emptyInput_returnsEmpty() {
        let result = DataController.tummyTimeDataByDay([])
        #expect(result.isEmpty)
    }

    @Test func tummyTimeDataByDay_nonTummyTime_filtersCorrectly() {
        let today = Calendar.current.startOfDay(for: Date())
        let activities = [
            Activity(kind: .sleep, timestamp: today, endTimestamp: today.addingTimeInterval(3600)),
            Activity(kind: .bathTime, timestamp: today)
        ]

        let result = DataController.tummyTimeDataByDay(activities)
        #expect(result.isEmpty)
    }

    @Test func averageTummyTimePerDay_multipleDays_calculatesCorrectly() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        let activities = [
            // Today: 20 minutes
            Activity(kind: .tummyTime, timestamp: today.addingTimeInterval(3600), endTimestamp: today.addingTimeInterval(4800)),
            // Yesterday: 30 minutes
            Activity(kind: .tummyTime, timestamp: yesterday.addingTimeInterval(3600), endTimestamp: yesterday.addingTimeInterval(5400))
        ]

        let result = DataController.averageTummyTimePerDay(activities)
        #expect(result == 25.0) // (20 + 30) / 2
    }

    @Test func averageTummyTimePerDay_emptyInput_returnsZero() {
        let result = DataController.averageTummyTimePerDay([])
        #expect(result == 0)
    }
}

// MARK: - Solid Food Analytics Tests

@MainActor
struct SolidFoodAnalyticsTests {

    @Test func solidFoodDataByDay_singleDay_groupsCorrectly() {
        let today = Calendar.current.startOfDay(for: Date())
        let activities = [
            Activity(kind: .solidFood, timestamp: today.addingTimeInterval(3600), foodType: "Banana"),
            Activity(kind: .solidFood, timestamp: today.addingTimeInterval(7200), foodType: "Apple")
        ]

        let result = DataController.solidFoodDataByDay(activities)

        #expect(result.count == 1)
        #expect(result[0].mealCount == 2)
        #expect(result[0].foods.count == 2)
    }

    @Test func solidFoodDataByDay_emptyInput_returnsEmpty() {
        let result = DataController.solidFoodDataByDay([])
        #expect(result.isEmpty)
    }

    @Test func uniqueFoodsIntroduced_returnsUniqueList() {
        let today = Calendar.current.startOfDay(for: Date())
        let activities = [
            Activity(kind: .solidFood, timestamp: today.addingTimeInterval(3600), foodType: "Banana"),
            Activity(kind: .solidFood, timestamp: today.addingTimeInterval(7200), foodType: "Apple"),
            Activity(kind: .solidFood, timestamp: today.addingTimeInterval(10800), foodType: "Banana") // duplicate
        ]

        let result = DataController.uniqueFoodsIntroduced(activities)

        #expect(result.count == 2)
        #expect(result.contains("Banana"))
        #expect(result.contains("Apple"))
    }

    @Test func uniqueFoodsIntroduced_emptyInput_returnsEmpty() {
        let result = DataController.uniqueFoodsIntroduced([])
        #expect(result.isEmpty)
    }

    @Test func foodsWithReactions_onlyReturnsReactedFoods() {
        let today = Calendar.current.startOfDay(for: Date())
        let activities = [
            Activity(kind: .solidFood, timestamp: today.addingTimeInterval(3600), foodType: "Banana", reactions: nil),
            Activity(kind: .solidFood, timestamp: today.addingTimeInterval(7200), foodType: "Peanut", reactions: "Mild rash"),
            Activity(kind: .solidFood, timestamp: today.addingTimeInterval(10800), foodType: "Apple", reactions: "")
        ]

        let result = DataController.foodsWithReactions(activities)

        #expect(result.count == 1)
        #expect(result.contains("Peanut"))
    }

    @Test func foodsWithReactions_emptyInput_returnsEmpty() {
        let result = DataController.foodsWithReactions([])
        #expect(result.isEmpty)
    }
}

// MARK: - Medicine Analytics Tests

@MainActor
struct MedicineAnalyticsTests {

    @Test func medicineDataByDay_singleDay_groupsCorrectly() {
        let today = Calendar.current.startOfDay(for: Date())
        let activities = [
            Activity(kind: .medicine, timestamp: today.addingTimeInterval(3600), medicineName: "Vitamin D", dosage: "1 drop"),
            Activity(kind: .medicine, timestamp: today.addingTimeInterval(7200), medicineName: "Tylenol", dosage: "2.5ml")
        ]

        let result = DataController.medicineDataByDay(activities)

        #expect(result.count == 1)
        #expect(result[0].doseCount == 2)
        #expect(result[0].medicines.count == 2)
    }

    @Test func medicineDataByDay_emptyInput_returnsEmpty() {
        let result = DataController.medicineDataByDay([])
        #expect(result.isEmpty)
    }

    @Test func uniqueMedicines_returnsUniqueList() {
        let today = Calendar.current.startOfDay(for: Date())
        let activities = [
            Activity(kind: .medicine, timestamp: today.addingTimeInterval(3600), medicineName: "Vitamin D", dosage: nil),
            Activity(kind: .medicine, timestamp: today.addingTimeInterval(7200), medicineName: "Tylenol", dosage: nil),
            Activity(kind: .medicine, timestamp: today.addingTimeInterval(10800), medicineName: "Vitamin D", dosage: nil) // duplicate
        ]

        let result = DataController.uniqueMedicines(activities)

        #expect(result.count == 2)
        #expect(result.contains("Vitamin D"))
        #expect(result.contains("Tylenol"))
    }

    @Test func uniqueMedicines_emptyInput_returnsEmpty() {
        let result = DataController.uniqueMedicines([])
        #expect(result.isEmpty)
    }
}

// MARK: - Growth Model Tests

struct GrowthMeasurementTests {

    @Test func growthMeasurement_weightInitialization_setsCorrectProperties() {
        let timestamp = Date()
        let measurement = GrowthMeasurement(measurementType: .weight, timestamp: timestamp, value: 5.5, notes: "Morning weight")

        #expect(measurement.measurementType == .weight)
        #expect(measurement.timestamp == timestamp)
        #expect(measurement.value == 5.5)
        #expect(measurement.notes == "Morning weight")
    }

    @Test func growthMeasurement_shortDisplay_formatsCorrectly() {
        let measurement = GrowthMeasurement(measurementType: .weight, timestamp: Date(), value: 6.2)
        #expect(measurement.shortDisplay == "Weight: 6.2 kg")
    }

    @Test func growthMeasurement_heightShortDisplay_formatsCorrectly() {
        let measurement = GrowthMeasurement(measurementType: .height, timestamp: Date(), value: 55.0)
        #expect(measurement.shortDisplay == "Height: 55.0 cm")
    }

    @Test func growthMeasurement_headCircumferenceShortDisplay_formatsCorrectly() {
        let measurement = GrowthMeasurement(measurementType: .headCircumference, timestamp: Date(), value: 35.5)
        #expect(measurement.shortDisplay == "Head Circumference: 35.5 cm")
    }

    @Test func growthMeasurementType_weight_hasCorrectUnit() {
        #expect(GrowthMeasurementType.weight.unit == "kg")
    }

    @Test func growthMeasurementType_height_hasCorrectUnit() {
        #expect(GrowthMeasurementType.height.unit == "cm")
    }

    @Test func growthMeasurementType_headCircumference_hasCorrectUnit() {
        #expect(GrowthMeasurementType.headCircumference.unit == "cm")
    }

    @Test func growthMeasurement_weightValidation_withinRange_isValid() {
        let measurement = GrowthMeasurement(measurementType: .weight, timestamp: Date(), value: 10.0)
        #expect(measurement.isValid == true)
    }

    @Test func growthMeasurement_weightValidation_exceedsMax_isInvalid() {
        let measurement = GrowthMeasurement(measurementType: .weight, timestamp: Date(), value: 35.0)
        #expect(measurement.isValid == false)
    }

    @Test func growthMeasurement_heightValidation_withinRange_isValid() {
        let measurement = GrowthMeasurement(measurementType: .height, timestamp: Date(), value: 60.0)
        #expect(measurement.isValid == true)
    }

    @Test func growthMeasurement_heightValidation_tooSmall_isInvalid() {
        let measurement = GrowthMeasurement(measurementType: .height, timestamp: Date(), value: 15.0)
        #expect(measurement.isValid == false)
    }
}

// MARK: - Milestone Model Tests

struct MilestoneTests {

    @Test func milestone_initialization_setsCorrectProperties() {
        let timestamp = Date()
        let milestone = Milestone(milestoneType: .firstSmile, timestamp: timestamp, notes: "So adorable!")

        #expect(milestone.milestoneType == .firstSmile)
        #expect(milestone.timestamp == timestamp)
        #expect(milestone.notes == "So adorable!")
        #expect(milestone.customTitle == nil)
        #expect(milestone.photoData == nil)
    }

    @Test func milestone_title_usesTypeDescription() {
        let milestone = Milestone(milestoneType: .rollOver, timestamp: Date())
        #expect(milestone.title == "Roll Over")
    }

    @Test func milestone_title_usesCustomTitleIfProvided() {
        let milestone = Milestone(milestoneType: .other, timestamp: Date(), customTitle: "First laugh")
        #expect(milestone.title == "First laugh")
    }

    @Test func milestone_image_returnsCorrectIcon() {
        let milestone = Milestone(milestoneType: .firstSteps, timestamp: Date())
        #expect(milestone.image == "figure.walk")
    }

    @Test func milestoneType_firstSmile_hasExpectedAgeRange() {
        let expected = MilestoneType.firstSmile.expectedAgeMonths
        #expect(expected != nil)
        #expect(expected!.min == 1)
        #expect(expected!.max == 3)
    }

    @Test func milestoneType_other_hasNoExpectedAgeRange() {
        let expected = MilestoneType.other.expectedAgeMonths
        #expect(expected == nil)
    }

    @Test func milestoneType_allCases_has16Types() {
        #expect(MilestoneType.allCases.count == 16)
    }

    @Test func milestone_ageAtMilestone_calculatesCorrectly() {
        let calendar = Calendar.current
        let birthDate = calendar.date(byAdding: .month, value: -6, to: Date())!
        let milestone = Milestone(milestoneType: .crawl, timestamp: Date())

        let age = milestone.ageAtMilestone(birthDate: birthDate)
        #expect(age == 6)
    }

    @Test func milestone_isWithinExpectedRange_whenEarly_returnsFalse() {
        let calendar = Calendar.current
        let birthDate = calendar.date(byAdding: .month, value: -3, to: Date())! // 3 months old
        let milestone = Milestone(milestoneType: .crawl, timestamp: Date()) // crawl expected at 7-10 months

        let result = milestone.isWithinExpectedRange(birthDate: birthDate)
        #expect(result == false)
    }

    @Test func milestone_isWithinExpectedRange_whenWithin_returnsTrue() {
        let calendar = Calendar.current
        let birthDate = calendar.date(byAdding: .month, value: -8, to: Date())! // 8 months old
        let milestone = Milestone(milestoneType: .crawl, timestamp: Date()) // crawl expected at 7-10 months

        let result = milestone.isWithinExpectedRange(birthDate: birthDate)
        #expect(result == true)
    }
}

// MARK: - Phase 5: iCloud & Family Sharing Tests

// MARK: - Permission Level Tests

struct PermissionLevelTests {

    @Test func permissionLevel_admin_hasCorrectDescription() {
        #expect(PermissionLevel.admin.description == "Admin")
    }

    @Test func permissionLevel_caregiver_hasCorrectDescription() {
        #expect(PermissionLevel.caregiver.description == "Caregiver")
    }

    @Test func permissionLevel_viewer_hasCorrectDescription() {
        #expect(PermissionLevel.viewer.description == "Viewer")
    }

    @Test func permissionLevel_admin_hasCorrectDetailedDescription() {
        #expect(PermissionLevel.admin.detailedDescription == "Full access and can manage family members")
    }

    @Test func permissionLevel_caregiver_hasCorrectDetailedDescription() {
        #expect(PermissionLevel.caregiver.detailedDescription == "Can add and edit activities")
    }

    @Test func permissionLevel_viewer_hasCorrectDetailedDescription() {
        #expect(PermissionLevel.viewer.detailedDescription == "Can only view activities")
    }

    @Test func permissionLevel_admin_hasCorrectIcon() {
        #expect(PermissionLevel.admin.icon == "crown.fill")
    }

    @Test func permissionLevel_caregiver_hasCorrectIcon() {
        #expect(PermissionLevel.caregiver.icon == "person.badge.plus")
    }

    @Test func permissionLevel_viewer_hasCorrectIcon() {
        #expect(PermissionLevel.viewer.icon == "eye.fill")
    }

    @Test func permissionLevel_allCases_containsThreeLevels() {
        #expect(PermissionLevel.allCases.count == 3)
    }

    @Test func permissionLevel_rawValues_matchExpected() {
        #expect(PermissionLevel.admin.rawValue == "admin")
        #expect(PermissionLevel.caregiver.rawValue == "caregiver")
        #expect(PermissionLevel.viewer.rawValue == "viewer")
    }
}

// MARK: - Family Member Tests

struct FamilyMemberTests {

    @Test func familyMember_initialization_setsCorrectProperties() {
        let member = FamilyMember(cloudKitUserID: "user-123", displayName: "Partner", permission: .caregiver)

        #expect(member.cloudKitUserID == "user-123")
        #expect(member.displayName == "Partner")
        #expect(member.permission == .caregiver)
        #expect(member.id != UUID()) // Should have a valid UUID
    }

    @Test func familyMember_canEdit_adminReturnsTrue() {
        let member = FamilyMember(cloudKitUserID: "user-123", displayName: "Admin", permission: .admin)
        #expect(member.canEdit == true)
    }

    @Test func familyMember_canEdit_caregiverReturnsTrue() {
        let member = FamilyMember(cloudKitUserID: "user-123", displayName: "Partner", permission: .caregiver)
        #expect(member.canEdit == true)
    }

    @Test func familyMember_canEdit_viewerReturnsFalse() {
        let member = FamilyMember(cloudKitUserID: "user-123", displayName: "Grandparent", permission: .viewer)
        #expect(member.canEdit == false)
    }

    @Test func familyMember_canManageMembers_adminReturnsTrue() {
        let member = FamilyMember(cloudKitUserID: "user-123", displayName: "Admin", permission: .admin)
        #expect(member.canManageMembers == true)
    }

    @Test func familyMember_canManageMembers_caregiverReturnsFalse() {
        let member = FamilyMember(cloudKitUserID: "user-123", displayName: "Partner", permission: .caregiver)
        #expect(member.canManageMembers == false)
    }

    @Test func familyMember_canManageMembers_viewerReturnsFalse() {
        let member = FamilyMember(cloudKitUserID: "user-123", displayName: "Grandparent", permission: .viewer)
        #expect(member.canManageMembers == false)
    }
}

// MARK: - Baby Model Tests

struct BabyModelTests {

    @Test func baby_initialization_setsCorrectProperties() {
        let birthDate = Calendar.current.date(byAdding: .month, value: -6, to: Date())!
        let baby = Baby(name: "Emma", birthDate: birthDate, ownerCloudKitID: "owner-123")

        #expect(baby.name == "Emma")
        #expect(baby.birthDate == birthDate)
        #expect(baby.ownerCloudKitID == "owner-123")
        #expect(baby.id != UUID()) // Should have a valid UUID
        #expect(baby.sharedWith.isEmpty)
    }

    @Test func baby_shortDisplay_returnsName() {
        let baby = Baby(name: "Emma", birthDate: Date())
        #expect(baby.shortDisplay == "Emma")
    }

    @Test func baby_ageInMonths_calculatesCorrectly() {
        let calendar = Calendar.current
        let birthDate = calendar.date(byAdding: .month, value: -6, to: Date())!
        let baby = Baby(name: "Emma", birthDate: birthDate)

        #expect(baby.ageInMonths == 6)
    }

    @Test func baby_ageDisplay_singleMonth_formatsCorrectly() {
        let calendar = Calendar.current
        let birthDate = calendar.date(byAdding: .month, value: -1, to: Date())!
        let baby = Baby(name: "Emma", birthDate: birthDate)

        #expect(baby.ageDisplay == "1 month")
    }

    @Test func baby_ageDisplay_multipleMonths_formatsCorrectly() {
        let calendar = Calendar.current
        let birthDate = calendar.date(byAdding: .month, value: -6, to: Date())!
        let baby = Baby(name: "Emma", birthDate: birthDate)

        #expect(baby.ageDisplay == "6 months")
    }

    @Test func baby_ageDisplay_oneYear_formatsCorrectly() {
        let calendar = Calendar.current
        let birthDate = calendar.date(byAdding: .year, value: -1, to: Date())!
        let baby = Baby(name: "Emma", birthDate: birthDate)

        #expect(baby.ageDisplay == "1 year")
    }

    @Test func baby_isValid_validName_returnsTrue() {
        let baby = Baby(name: "Emma", birthDate: Date())
        #expect(baby.isValid == true)
    }

    @Test func baby_isValid_emptyName_returnsFalse() {
        let baby = Baby(name: "", birthDate: Date())
        #expect(baby.isValid == false)
    }

    @Test func baby_isValid_whitespaceOnlyName_returnsFalse() {
        let baby = Baby(name: "   ", birthDate: Date())
        #expect(baby.isValid == false)
    }

    @Test func baby_validationErrors_validName_returnsEmpty() {
        let baby = Baby(name: "Emma", birthDate: Date())
        #expect(baby.validationErrors.isEmpty)
    }

    @Test func baby_validationErrors_emptyName_returnsError() {
        let baby = Baby(name: "", birthDate: Date())
        let errors = baby.validationErrors

        #expect(errors.count == 1)
        #expect(errors.contains("Name cannot be empty"))
    }

    // MARK: - Family Sharing Tests

    @Test func baby_addFamilyMember_addsCorrectly() {
        let baby = Baby(name: "Emma", birthDate: Date())
        let member = baby.addFamilyMember(cloudKitUserID: "user-123", displayName: "Partner", permission: .caregiver)

        #expect(baby.sharedWith.count == 1)
        #expect(member.displayName == "Partner")
        #expect(member.permission == .caregiver)
    }

    @Test func baby_removeFamilyMember_removesCorrectly() {
        let baby = Baby(name: "Emma", birthDate: Date())
        _ = baby.addFamilyMember(cloudKitUserID: "user-123", displayName: "Partner", permission: .caregiver)

        baby.removeFamilyMember(cloudKitUserID: "user-123")

        #expect(baby.sharedWith.isEmpty)
    }

    @Test func baby_removeFamilyMember_nonExistentUser_doesNothing() {
        let baby = Baby(name: "Emma", birthDate: Date())
        _ = baby.addFamilyMember(cloudKitUserID: "user-123", displayName: "Partner", permission: .caregiver)

        baby.removeFamilyMember(cloudKitUserID: "non-existent")

        #expect(baby.sharedWith.count == 1)
    }

    @Test func baby_updatePermission_updatesCorrectly() {
        let baby = Baby(name: "Emma", birthDate: Date())
        let member = baby.addFamilyMember(cloudKitUserID: "user-123", displayName: "Partner", permission: .caregiver)

        baby.updatePermission(for: "user-123", to: .admin)

        #expect(member.permission == .admin)
    }

    @Test func baby_permission_ownerReturnsAdmin() {
        let baby = Baby(name: "Emma", birthDate: Date(), ownerCloudKitID: "owner-123")

        let permission = baby.permission(for: "owner-123")

        #expect(permission == .admin)
    }

    @Test func baby_permission_memberReturnsTheirPermission() {
        let baby = Baby(name: "Emma", birthDate: Date())
        _ = baby.addFamilyMember(cloudKitUserID: "user-123", displayName: "Partner", permission: .caregiver)

        let permission = baby.permission(for: "user-123")

        #expect(permission == .caregiver)
    }

    @Test func baby_permission_unknownUserReturnsNil() {
        let baby = Baby(name: "Emma", birthDate: Date())

        let permission = baby.permission(for: "unknown-user")

        #expect(permission == nil)
    }

    @Test func baby_hasPermission_viewer_allLevelsHaveAccess() {
        let baby = Baby(name: "Emma", birthDate: Date(), ownerCloudKitID: "owner-123")
        _ = baby.addFamilyMember(cloudKitUserID: "caregiver-123", displayName: "Partner", permission: .caregiver)
        _ = baby.addFamilyMember(cloudKitUserID: "viewer-123", displayName: "Grandparent", permission: .viewer)

        #expect(baby.hasPermission(.viewer, for: "owner-123") == true)
        #expect(baby.hasPermission(.viewer, for: "caregiver-123") == true)
        #expect(baby.hasPermission(.viewer, for: "viewer-123") == true)
    }

    @Test func baby_hasPermission_caregiver_onlyCaregiverAndAdminHaveAccess() {
        let baby = Baby(name: "Emma", birthDate: Date(), ownerCloudKitID: "owner-123")
        _ = baby.addFamilyMember(cloudKitUserID: "caregiver-123", displayName: "Partner", permission: .caregiver)
        _ = baby.addFamilyMember(cloudKitUserID: "viewer-123", displayName: "Grandparent", permission: .viewer)

        #expect(baby.hasPermission(.caregiver, for: "owner-123") == true)
        #expect(baby.hasPermission(.caregiver, for: "caregiver-123") == true)
        #expect(baby.hasPermission(.caregiver, for: "viewer-123") == false)
    }

    @Test func baby_hasPermission_admin_onlyAdminHasAccess() {
        let baby = Baby(name: "Emma", birthDate: Date(), ownerCloudKitID: "owner-123")
        _ = baby.addFamilyMember(cloudKitUserID: "caregiver-123", displayName: "Partner", permission: .caregiver)
        _ = baby.addFamilyMember(cloudKitUserID: "viewer-123", displayName: "Grandparent", permission: .viewer)

        #expect(baby.hasPermission(.admin, for: "owner-123") == true)
        #expect(baby.hasPermission(.admin, for: "caregiver-123") == false)
        #expect(baby.hasPermission(.admin, for: "viewer-123") == false)
    }

    @Test func baby_allUserIDs_includesOwnerAndMembers() {
        let baby = Baby(name: "Emma", birthDate: Date(), ownerCloudKitID: "owner-123")
        _ = baby.addFamilyMember(cloudKitUserID: "user-1", displayName: "Partner", permission: .caregiver)
        _ = baby.addFamilyMember(cloudKitUserID: "user-2", displayName: "Grandparent", permission: .viewer)

        let allIDs = baby.allUserIDs

        #expect(allIDs.count == 3)
        #expect(allIDs.contains("owner-123"))
        #expect(allIDs.contains("user-1"))
        #expect(allIDs.contains("user-2"))
    }

    @Test func baby_allUserIDs_ownerIsFirst() {
        let baby = Baby(name: "Emma", birthDate: Date(), ownerCloudKitID: "owner-123")
        _ = baby.addFamilyMember(cloudKitUserID: "user-1", displayName: "Partner", permission: .caregiver)

        let allIDs = baby.allUserIDs

        #expect(allIDs.first == "owner-123")
    }
}

// MARK: - Activity Contributor Fields Tests

struct ActivityContributorTests {

    @Test func activity_contributorFields_setCorrectly() {
        let activity = Activity(
            kind: .milk,
            timestamp: Date(),
            endTimestamp: Date().addingTimeInterval(1800),
            amount: 100,
            contributorId: "user-123",
            contributorName: "Partner"
        )

        #expect(activity.contributorId == "user-123")
        #expect(activity.contributorName == "Partner")
        #expect(activity.lastModified != nil)
    }

    @Test func activity_contributorFields_defaultToNil() {
        let activity = Activity(kind: .wetDiaper, timestamp: Date())

        #expect(activity.contributorId == nil)
        #expect(activity.contributorName == nil)
    }
}

// MARK: - GrowthMeasurement Contributor Fields Tests

struct GrowthMeasurementContributorTests {

    @Test func growthMeasurement_contributorFields_setCorrectly() {
        let measurement = GrowthMeasurement(
            measurementType: .weight,
            timestamp: Date(),
            value: 5.5,
            contributorId: "user-123",
            contributorName: "Partner"
        )

        #expect(measurement.contributorId == "user-123")
        #expect(measurement.contributorName == "Partner")
        #expect(measurement.lastModified != nil)
    }

    @Test func growthMeasurement_contributorFields_defaultToNil() {
        let measurement = GrowthMeasurement(measurementType: .weight, timestamp: Date(), value: 5.5)

        #expect(measurement.contributorId == nil)
        #expect(measurement.contributorName == nil)
    }
}

// MARK: - Milestone Contributor Fields Tests

struct MilestoneContributorTests {

    @Test func milestone_contributorFields_setCorrectly() {
        let milestone = Milestone(
            milestoneType: .firstSmile,
            timestamp: Date(),
            contributorId: "user-123",
            contributorName: "Partner"
        )

        #expect(milestone.contributorId == "user-123")
        #expect(milestone.contributorName == "Partner")
        #expect(milestone.lastModified != nil)
    }

    @Test func milestone_contributorFields_defaultToNil() {
        let milestone = Milestone(milestoneType: .firstSmile, timestamp: Date())

        #expect(milestone.contributorId == nil)
        #expect(milestone.contributorName == nil)
    }
}

// MARK: - Phase 6: AI-Powered Smart Reminders Tests

// MARK: - Activity Pattern Tests

struct ActivityPatternTests {

    @Test func activityPattern_initialization_setsCorrectProperties() {
        let pattern = ActivityPattern(
            activityKind: .milk,
            typicalIntervalMinutes: 180.0,
            confidenceScore: 0.85,
            timeOfDayDistribution: [8: 0.3, 12: 0.4, 18: 0.3],
            sampleSize: 20,
            lastUpdated: Date()
        )

        #expect(pattern.activityKind == .milk)
        #expect(pattern.typicalIntervalMinutes == 180.0)
        #expect(pattern.confidenceScore == 0.85)
        #expect(pattern.sampleSize == 20)
    }

    @Test func activityPattern_intervalDescription_hours_formatsCorrectly() {
        let pattern = ActivityPattern(
            activityKind: .sleep,
            typicalIntervalMinutes: 180.0,
            confidenceScore: 0.7,
            timeOfDayDistribution: [:],
            sampleSize: 10,
            lastUpdated: Date()
        )

        #expect(pattern.intervalDescription == "3h")
    }

    @Test func activityPattern_intervalDescription_hoursAndMinutes_formatsCorrectly() {
        let pattern = ActivityPattern(
            activityKind: .milk,
            typicalIntervalMinutes: 150.0,
            confidenceScore: 0.7,
            timeOfDayDistribution: [:],
            sampleSize: 10,
            lastUpdated: Date()
        )

        #expect(pattern.intervalDescription == "2h 30m")
    }

    @Test func activityPattern_intervalDescription_minutesOnly_formatsCorrectly() {
        let pattern = ActivityPattern(
            activityKind: .wetDiaper,
            typicalIntervalMinutes: 45.0,
            confidenceScore: 0.7,
            timeOfDayDistribution: [:],
            sampleSize: 10,
            lastUpdated: Date()
        )

        #expect(pattern.intervalDescription == "45m")
    }

    @Test func activityPattern_confidenceDescription_high_returnsHigh() {
        let pattern = ActivityPattern(
            activityKind: .sleep,
            typicalIntervalMinutes: 180.0,
            confidenceScore: 0.85,
            timeOfDayDistribution: [:],
            sampleSize: 10,
            lastUpdated: Date()
        )

        #expect(pattern.confidenceDescription == "High")
    }

    @Test func activityPattern_confidenceDescription_medium_returnsMedium() {
        let pattern = ActivityPattern(
            activityKind: .sleep,
            typicalIntervalMinutes: 180.0,
            confidenceScore: 0.6,
            timeOfDayDistribution: [:],
            sampleSize: 10,
            lastUpdated: Date()
        )

        #expect(pattern.confidenceDescription == "Medium")
    }

    @Test func activityPattern_confidenceDescription_low_returnsLow() {
        let pattern = ActivityPattern(
            activityKind: .sleep,
            typicalIntervalMinutes: 180.0,
            confidenceScore: 0.3,
            timeOfDayDistribution: [:],
            sampleSize: 10,
            lastUpdated: Date()
        )

        #expect(pattern.confidenceDescription == "Low")
    }

    @Test func activityPattern_peakHours_returnsTopThree() {
        let pattern = ActivityPattern(
            activityKind: .milk,
            typicalIntervalMinutes: 180.0,
            confidenceScore: 0.7,
            timeOfDayDistribution: [8: 0.4, 12: 0.3, 16: 0.2, 20: 0.1],
            sampleSize: 10,
            lastUpdated: Date()
        )

        let peakHours = pattern.peakHours
        #expect(peakHours.count == 3)
        #expect(peakHours[0] == 8)  // Highest probability
        #expect(peakHours[1] == 12) // Second highest
        #expect(peakHours[2] == 16) // Third highest
    }
}

// MARK: - Reminder Settings Tests

struct ReminderSettingsTests {

    @Test func reminderSettings_defaultValues_areCorrect() {
        let settings = ReminderSettings()

        #expect(settings.isEnabled == true)
        #expect(settings.enabledActivityKinds.count == ActivityKind.allCases.count)
        #expect(settings.sensitivity == .balanced)
        #expect(settings.quietHoursEnabled == true)
        #expect(settings.quietHoursStart == 22)
        #expect(settings.quietHoursEnd == 7)
        #expect(settings.minimumConfidence == 0.5)
    }

    @Test func reminderSettings_isEnabledForKind_whenEnabledAndKindIncluded_returnsTrue() {
        var settings = ReminderSettings()
        settings.isEnabled = true
        settings.enabledActivityKinds = [.milk, .sleep]

        #expect(settings.isEnabled(for: .milk) == true)
        #expect(settings.isEnabled(for: .sleep) == true)
    }

    @Test func reminderSettings_isEnabledForKind_whenKindNotIncluded_returnsFalse() {
        var settings = ReminderSettings()
        settings.isEnabled = true
        settings.enabledActivityKinds = [.milk]

        #expect(settings.isEnabled(for: .sleep) == false)
    }

    @Test func reminderSettings_isEnabledForKind_whenDisabled_returnsFalse() {
        var settings = ReminderSettings()
        settings.isEnabled = false
        settings.enabledActivityKinds = [.milk, .sleep]

        #expect(settings.isEnabled(for: .milk) == false)
    }

    @Test func reminderSettings_isQuietHours_duringQuietHours_returnsTrue() {
        var settings = ReminderSettings()
        settings.quietHoursEnabled = true
        settings.quietHoursStart = 22  // 10 PM
        settings.quietHoursEnd = 7     // 7 AM

        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = 23  // 11 PM (within quiet hours)
        let lateNight = calendar.date(from: components)!

        #expect(settings.isQuietHours(at: lateNight) == true)
    }

    @Test func reminderSettings_isQuietHours_outsideQuietHours_returnsFalse() {
        var settings = ReminderSettings()
        settings.quietHoursEnabled = true
        settings.quietHoursStart = 22
        settings.quietHoursEnd = 7

        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = 12  // Noon (outside quiet hours)
        let noon = calendar.date(from: components)!

        #expect(settings.isQuietHours(at: noon) == false)
    }

    @Test func reminderSettings_isQuietHours_whenDisabled_returnsFalse() {
        var settings = ReminderSettings()
        settings.quietHoursEnabled = false
        settings.quietHoursStart = 22
        settings.quietHoursEnd = 7

        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = 23
        let lateNight = calendar.date(from: components)!

        #expect(settings.isQuietHours(at: lateNight) == false)
    }

    @Test func reminderSettings_sensitivity_conservativeHasHigherMinimumConfidence() {
        let conservative = ReminderSettings.Sensitivity.conservative
        let balanced = ReminderSettings.Sensitivity.balanced
        let aggressive = ReminderSettings.Sensitivity.aggressive

        #expect(conservative.minimumConfidence > balanced.minimumConfidence)
        #expect(balanced.minimumConfidence > aggressive.minimumConfidence)
    }

    @Test func reminderSettings_sensitivity_conservativeHasHigherIntervalMultiplier() {
        let conservative = ReminderSettings.Sensitivity.conservative
        let balanced = ReminderSettings.Sensitivity.balanced
        let aggressive = ReminderSettings.Sensitivity.aggressive

        #expect(conservative.intervalMultiplier > balanced.intervalMultiplier)
        #expect(balanced.intervalMultiplier > aggressive.intervalMultiplier)
    }

    @Test func reminderSettings_sensitivity_allCases_containsThreeLevels() {
        #expect(ReminderSettings.Sensitivity.allCases.count == 3)
    }
}

// MARK: - Activity Prediction Tests

struct ActivityPredictionTests {

    @Test func activityPrediction_generateMessage_milk_includesTimeInfo() {
        let message = ActivityPrediction.generateMessage(for: .milk, timeSinceLast: 7200) // 2 hours

        #expect(message.contains("feeding"))
        #expect(message.contains("2 hours"))
    }

    @Test func activityPrediction_generateMessage_sleep_includesTimeInfo() {
        let message = ActivityPrediction.generateMessage(for: .sleep, timeSinceLast: 10800) // 3 hours

        #expect(message.contains("sleepy") || message.contains("sleep"))
        #expect(message.contains("3") || message.contains("hours"))
    }

    @Test func activityPrediction_generateMessage_diaper_includesTimeInfo() {
        let message = ActivityPrediction.generateMessage(for: .wetDiaper, timeSinceLast: 3600) // 1 hour

        #expect(message.contains("diaper"))
    }

    @Test func activityPrediction_timeUntil_futureTime_isPositive() {
        let pattern = ActivityPattern(
            activityKind: .milk,
            typicalIntervalMinutes: 180.0,
            confidenceScore: 0.7,
            timeOfDayDistribution: [:],
            sampleSize: 10,
            lastUpdated: Date()
        )

        let prediction = ActivityPrediction(
            activityKind: .milk,
            predictedTime: Date().addingTimeInterval(3600), // 1 hour in future
            confidence: 0.7,
            basedOnPattern: pattern,
            message: "Test message"
        )

        #expect(prediction.timeUntil > 0)
        #expect(prediction.isOverdue == false)
    }

    @Test func activityPrediction_timeUntil_pastTime_isNegative() {
        let pattern = ActivityPattern(
            activityKind: .milk,
            typicalIntervalMinutes: 180.0,
            confidenceScore: 0.7,
            timeOfDayDistribution: [:],
            sampleSize: 10,
            lastUpdated: Date()
        )

        let prediction = ActivityPrediction(
            activityKind: .milk,
            predictedTime: Date().addingTimeInterval(-3600), // 1 hour in past
            confidence: 0.7,
            basedOnPattern: pattern,
            message: "Test message"
        )

        #expect(prediction.timeUntil < 0)
        #expect(prediction.isOverdue == true)
    }

    @Test func activityPrediction_timeUntilDescription_inHours_formatsCorrectly() {
        let pattern = ActivityPattern(
            activityKind: .milk,
            typicalIntervalMinutes: 180.0,
            confidenceScore: 0.7,
            timeOfDayDistribution: [:],
            sampleSize: 10,
            lastUpdated: Date()
        )

        let prediction = ActivityPrediction(
            activityKind: .milk,
            predictedTime: Date().addingTimeInterval(7200), // 2 hours
            confidence: 0.7,
            basedOnPattern: pattern,
            message: "Test message"
        )

        let description = prediction.timeUntilDescription
        #expect(description.contains("2h") || description.contains("1h"))
    }
}

// MARK: - Scheduled Reminder Tests

struct ScheduledReminderTests {

    @Test func scheduledReminder_initialization_setsCorrectProperties() {
        let reminder = ScheduledReminder(
            activityKind: .milk,
            scheduledTime: Date(),
            message: "Time to feed",
            isRepeating: false,
            priority: .high
        )

        #expect(reminder.activityKind == .milk)
        #expect(reminder.message == "Time to feed")
        #expect(reminder.isRepeating == false)
        #expect(reminder.priority == .high)
    }

    @Test func scheduledReminder_priority_highHasSound() {
        #expect(ScheduledReminder.ReminderPriority.high.notificationSound == true)
    }

    @Test func scheduledReminder_priority_mediumHasSound() {
        #expect(ScheduledReminder.ReminderPriority.medium.notificationSound == true)
    }

    @Test func scheduledReminder_priority_lowHasNoSound() {
        #expect(ScheduledReminder.ReminderPriority.low.notificationSound == false)
    }

    @Test func scheduledReminder_priority_allCases_containsThreeLevels() {
        #expect(ScheduledReminder.ReminderPriority.allCases.count == 3)
    }
}

// MARK: - Pattern Analysis Tests

@MainActor
struct PatternAnalysisTests {

    @Test func analyzeActivityPatterns_emptyInput_returnsEmpty() {
        let patterns = DataController.analyzeActivityPatterns([])
        #expect(patterns.isEmpty)
    }

    @Test func analyzeActivityPatterns_insufficientData_returnsEmpty() {
        let today = Calendar.current.startOfDay(for: Date())
        let activities = [
            Activity(kind: .milk, timestamp: today, endTimestamp: today.addingTimeInterval(1800), amount: 100),
            Activity(kind: .milk, timestamp: today.addingTimeInterval(3600), endTimestamp: today.addingTimeInterval(5400), amount: 100)
        ]

        // Default minimum sample size is 5
        let patterns = DataController.analyzeActivityPatterns(activities)
        #expect(patterns[.milk] == nil)
    }

    @Test func analyzeActivityPatterns_sufficientData_returnsPattern() {
        let today = Calendar.current.startOfDay(for: Date())
        var activities: [Activity] = []

        // Create 6 milk activities with 2-hour intervals
        for i in 0..<6 {
            let timestamp = today.addingTimeInterval(Double(i) * 7200) // 2 hours apart
            activities.append(Activity(kind: .milk, timestamp: timestamp, endTimestamp: timestamp.addingTimeInterval(1800), amount: 100))
        }

        let patterns = DataController.analyzeActivityPatterns(activities, minimumSampleSize: 5)

        #expect(patterns[.milk] != nil)
        if let milkPattern = patterns[.milk] {
            #expect(milkPattern.activityKind == .milk)
            #expect(milkPattern.sampleSize == 6)
            // Interval should be around 90 minutes (2 hours - 30 min feeding = 90 min between end and start)
            #expect(milkPattern.typicalIntervalMinutes > 0)
        }
    }

    @Test func analyzeActivityPatterns_multipleKinds_returnsMultiplePatterns() {
        let today = Calendar.current.startOfDay(for: Date())
        var activities: [Activity] = []

        // Create 6 milk activities
        for i in 0..<6 {
            let timestamp = today.addingTimeInterval(Double(i) * 7200)
            activities.append(Activity(kind: .milk, timestamp: timestamp, endTimestamp: timestamp.addingTimeInterval(1800), amount: 100))
        }

        // Create 6 sleep activities
        for i in 0..<6 {
            let timestamp = today.addingTimeInterval(Double(i) * 14400) // 4 hours apart
            activities.append(Activity(kind: .sleep, timestamp: timestamp, endTimestamp: timestamp.addingTimeInterval(3600)))
        }

        let patterns = DataController.analyzeActivityPatterns(activities, minimumSampleSize: 5)

        #expect(patterns[.milk] != nil)
        #expect(patterns[.sleep] != nil)
    }

    @Test func typicalFeedingIntervalMinutes_emptyInput_returnsNil() {
        let result = DataController.typicalFeedingIntervalMinutes([])
        #expect(result == nil)
    }

    @Test func typicalFeedingIntervalMinutes_singleFeeding_returnsNil() {
        let today = Calendar.current.startOfDay(for: Date())
        let activities = [
            Activity(kind: .milk, timestamp: today, endTimestamp: today.addingTimeInterval(1800), amount: 100)
        ]

        let result = DataController.typicalFeedingIntervalMinutes(activities)
        #expect(result == nil)
    }

    @Test func typicalFeedingIntervalMinutes_multipleFeedings_returnsMedian() {
        let today = Calendar.current.startOfDay(for: Date())
        let activities = [
            Activity(kind: .milk, timestamp: today, endTimestamp: today.addingTimeInterval(1800), amount: 100),
            Activity(kind: .milk, timestamp: today.addingTimeInterval(7200), endTimestamp: today.addingTimeInterval(9000), amount: 100), // 2 hours later
            Activity(kind: .milk, timestamp: today.addingTimeInterval(14400), endTimestamp: today.addingTimeInterval(16200), amount: 100) // 2 hours later
        ]

        let result = DataController.typicalFeedingIntervalMinutes(activities)
        #expect(result != nil)
        if let interval = result {
            // Should be around 120 minutes (2 hours)
            #expect(interval == 120.0)
        }
    }

    @Test func typicalSleepDurationMinutes_emptyInput_returnsNil() {
        let result = DataController.typicalSleepDurationMinutes([])
        #expect(result == nil)
    }

    @Test func typicalSleepDurationMinutes_insufficientData_returnsNil() {
        let today = Calendar.current.startOfDay(for: Date())
        let activities = [
            Activity(kind: .sleep, timestamp: today, endTimestamp: today.addingTimeInterval(3600)),
            Activity(kind: .sleep, timestamp: today.addingTimeInterval(7200), endTimestamp: today.addingTimeInterval(10800))
        ]

        // Needs at least 3 activities
        let result = DataController.typicalSleepDurationMinutes(activities)
        #expect(result == nil)
    }

    @Test func typicalSleepDurationMinutes_sufficientData_returnsMedian() {
        let today = Calendar.current.startOfDay(for: Date())
        let activities = [
            Activity(kind: .sleep, timestamp: today, endTimestamp: today.addingTimeInterval(3600)), // 1 hour
            Activity(kind: .sleep, timestamp: today.addingTimeInterval(7200), endTimestamp: today.addingTimeInterval(14400)), // 2 hours
            Activity(kind: .sleep, timestamp: today.addingTimeInterval(21600), endTimestamp: today.addingTimeInterval(27000)) // 1.5 hours
        ]

        let result = DataController.typicalSleepDurationMinutes(activities)
        #expect(result != nil)
        if let duration = result {
            // Median of [60, 90, 120] = 90
            #expect(duration == 90.0)
        }
    }
}

// MARK: - Quick Action Service Tests

@MainActor
struct QuickActionShortcutItemTests {
    @Test func shortcutItem_sleep_hasCorrectTypeAndTitle() {
        let item = QuickActionService.shortcutItem(for: .sleep)
        #expect(item.type == "com.babyactivity.quickaction.sleep")
        #expect(item.localizedTitle == "Log Sleep")
    }

    @Test func shortcutItem_milk_hasCorrectTypeAndTitle() {
        let item = QuickActionService.shortcutItem(for: .milk)
        #expect(item.type == "com.babyactivity.quickaction.milk")
        #expect(item.localizedTitle == "Log Milk")
    }

    @Test func shortcutItem_wetDiaper_hasCorrectTypeAndTitle() {
        let item = QuickActionService.shortcutItem(for: .wetDiaper)
        #expect(item.type == "com.babyactivity.quickaction.wetDiaper")
        #expect(item.localizedTitle == "Log Wet Diaper")
    }

    @Test func shortcutItem_dirtyDiaper_hasCorrectTypeAndTitle() {
        let item = QuickActionService.shortcutItem(for: .dirtyDiaper)
        #expect(item.type == "com.babyactivity.quickaction.dirtyDiaper")
        #expect(item.localizedTitle == "Log Dirty Diaper")
    }

    @Test func shortcutItem_solidFood_hasCorrectTypeAndTitle() {
        let item = QuickActionService.shortcutItem(for: .solidFood)
        #expect(item.type == "com.babyactivity.quickaction.solidFood")
        #expect(item.localizedTitle == "Log Solid Food")
    }

    @Test func shortcutItem_tummyTime_hasCorrectTypeAndTitle() {
        let item = QuickActionService.shortcutItem(for: .tummyTime)
        #expect(item.type == "com.babyactivity.quickaction.tummyTime")
        #expect(item.localizedTitle == "Log Tummy Time")
    }

    @Test func shortcutItem_bathTime_hasCorrectTypeAndTitle() {
        let item = QuickActionService.shortcutItem(for: .bathTime)
        #expect(item.type == "com.babyactivity.quickaction.bathTime")
        #expect(item.localizedTitle == "Log Bath Time")
    }

    @Test func shortcutItem_medicine_hasCorrectTypeAndTitle() {
        let item = QuickActionService.shortcutItem(for: .medicine)
        #expect(item.type == "com.babyactivity.quickaction.medicine")
        #expect(item.localizedTitle == "Log Medicine")
    }

    @Test func shortcutItem_allKinds_haveUniqueTypes() {
        let items = ActivityKind.allCases.map { QuickActionService.shortcutItem(for: $0) }
        let types = items.map { $0.type }
        #expect(Set(types).count == ActivityKind.allCases.count)
    }
}

@MainActor
struct QuickActionKindParsingTests {
    @Test func activityKind_validShortcutItem_returnsCorrectKind() {
        for kind in ActivityKind.allCases {
            let item = QuickActionService.shortcutItem(for: kind)
            let parsed = QuickActionService.activityKind(from: item)
            #expect(parsed == kind)
        }
    }

    @Test func activityKind_invalidPrefix_returnsNil() {
        let item = UIApplicationShortcutItem(type: "com.other.app.sleep", localizedTitle: "Sleep")
        let parsed = QuickActionService.activityKind(from: item)
        #expect(parsed == nil)
    }

    @Test func activityKind_invalidRawValue_returnsNil() {
        let item = UIApplicationShortcutItem(
            type: QuickActionService.shortcutTypePrefix + "nonexistent",
            localizedTitle: "Invalid"
        )
        let parsed = QuickActionService.activityKind(from: item)
        #expect(parsed == nil)
    }

    @Test func activityKind_emptyType_returnsNil() {
        let item = UIApplicationShortcutItem(type: "", localizedTitle: "Empty")
        let parsed = QuickActionService.activityKind(from: item)
        #expect(parsed == nil)
    }
}

@MainActor
struct QuickActionTopKindsTests {
    @Test func topActivityKinds_emptyActivities_returnsDefaults() {
        let result = QuickActionService.topActivityKinds(from: [])
        #expect(result == QuickActionService.defaultQuickActionKinds)
    }

    @Test func topActivityKinds_singleKind_returnsThatKind() {
        let activities = [
            Activity(kind: .sleep, timestamp: Date()),
            Activity(kind: .sleep, timestamp: Date()),
        ]
        let result = QuickActionService.topActivityKinds(from: activities)
        #expect(result.count == 1)
        #expect(result[0] == .sleep)
    }

    @Test func topActivityKinds_multipleKinds_returnsMostFrequentFirst() {
        let activities = [
            Activity(kind: .milk, timestamp: Date()),
            Activity(kind: .milk, timestamp: Date()),
            Activity(kind: .milk, timestamp: Date()),
            Activity(kind: .sleep, timestamp: Date()),
            Activity(kind: .sleep, timestamp: Date()),
            Activity(kind: .wetDiaper, timestamp: Date()),
        ]
        let result = QuickActionService.topActivityKinds(from: activities)
        #expect(result.count == 3)
        #expect(result[0] == .milk)
        #expect(result[1] == .sleep)
        #expect(result[2] == .wetDiaper)
    }

    @Test func topActivityKinds_moreThanLimit_returnsOnlyLimit() {
        let activities = [
            Activity(kind: .milk, timestamp: Date()),
            Activity(kind: .sleep, timestamp: Date()),
            Activity(kind: .wetDiaper, timestamp: Date()),
            Activity(kind: .dirtyDiaper, timestamp: Date()),
            Activity(kind: .solidFood, timestamp: Date()),
            Activity(kind: .tummyTime, timestamp: Date()),
        ]
        let result = QuickActionService.topActivityKinds(from: activities, limit: 4)
        #expect(result.count == 4)
    }

    @Test func topActivityKinds_customLimit_respectsLimit() {
        let activities = [
            Activity(kind: .milk, timestamp: Date()),
            Activity(kind: .sleep, timestamp: Date()),
            Activity(kind: .wetDiaper, timestamp: Date()),
        ]
        let result = QuickActionService.topActivityKinds(from: activities, limit: 2)
        #expect(result.count == 2)
    }

    @Test func topActivityKinds_defaultLimit_isFour() {
        let activities = [
            Activity(kind: .milk, timestamp: Date()),
            Activity(kind: .milk, timestamp: Date()),
            Activity(kind: .sleep, timestamp: Date()),
            Activity(kind: .sleep, timestamp: Date()),
            Activity(kind: .wetDiaper, timestamp: Date()),
            Activity(kind: .wetDiaper, timestamp: Date()),
            Activity(kind: .dirtyDiaper, timestamp: Date()),
            Activity(kind: .dirtyDiaper, timestamp: Date()),
            Activity(kind: .solidFood, timestamp: Date()),
        ]
        let result = QuickActionService.topActivityKinds(from: activities)
        #expect(result.count == 4)
    }
}

@MainActor
struct QuickActionShortcutTitleTests {
    @Test func shortcutTitle_allKinds_startsWithLog() {
        for kind in ActivityKind.allCases {
            let title = QuickActionService.shortcutTitle(for: kind)
            #expect(title.hasPrefix("Log "))
        }
    }

    @Test func shortcutTitle_allKinds_areNonEmpty() {
        for kind in ActivityKind.allCases {
            let title = QuickActionService.shortcutTitle(for: kind)
            #expect(!title.isEmpty)
        }
    }
}

@MainActor
struct QuickActionHandleShortcutTests {
    @Test func handleShortcutItem_validItem_setsPendingAction() {
        let service = QuickActionService()
        let item = QuickActionService.shortcutItem(for: .milk)
        let handled = service.handleShortcutItem(item)
        #expect(handled == true)
        #expect(service.pendingActionKind == .milk)
    }

    @Test func handleShortcutItem_invalidItem_returnsFalse() {
        let service = QuickActionService()
        let item = UIApplicationShortcutItem(type: "com.other.action", localizedTitle: "Other")
        let handled = service.handleShortcutItem(item)
        #expect(handled == false)
        #expect(service.pendingActionKind == nil)
    }

    @Test func handleShortcutItem_allKinds_setsCorrectPendingAction() {
        for kind in ActivityKind.allCases {
            let service = QuickActionService()
            let item = QuickActionService.shortcutItem(for: kind)
            let handled = service.handleShortcutItem(item)
            #expect(handled == true)
            #expect(service.pendingActionKind == kind)
        }
    }
}
