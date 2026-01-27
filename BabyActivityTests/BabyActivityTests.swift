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

struct DataControllerTests {

    // MARK: - sliceDataToPlot Tests

    @Test func sliceDataToPlot_singleDayActivity_returnsOneSlice() async {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let start = startOfDay.addingTimeInterval(2 * 60 * 60) // 2 AM
        let end = startOfDay.addingTimeInterval(4 * 60 * 60) // 4 AM

        let activity = Activity(kind: .sleep, timestamp: start, endTimestamp: end)
        let result = await DataController.sliceDataToPlot(sleepActivities: [activity])

        #expect(result.count == 1)
        #expect(result[0].start == start)
        #expect(result[0].end == end)
    }

    @Test func sliceDataToPlot_crossMidnightActivity_returnsTwoSlices() async {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let start = startOfDay.addingTimeInterval(23 * 60 * 60) // 11 PM
        let end = startOfDay.addingTimeInterval(26 * 60 * 60) // 2 AM next day

        let activity = Activity(kind: .sleep, timestamp: start, endTimestamp: end)
        let result = await DataController.sliceDataToPlot(sleepActivities: [activity])

        #expect(result.count == 2)
        // First slice: from 11 PM to just before midnight
        #expect(result[0].start == start)
        // Second slice: from midnight to 2 AM
        #expect(calendar.isDate(result[1].start, inSameDayAs: end))
        #expect(result[1].end == end)
    }

    @Test func sliceDataToPlot_emptyInput_returnsEmpty() async {
        let result = await DataController.sliceDataToPlot(sleepActivities: [])
        #expect(result.isEmpty)
    }

    @Test func sliceDataToPlot_activityWithNoEndTime_treatsSameAsStart() async {
        let start = Date()
        let activity = Activity(kind: .sleep, timestamp: start, endTimestamp: nil, amount: nil)
        let result = await DataController.sliceDataToPlot(sleepActivities: [activity])

        #expect(result.count == 1)
        #expect(result[0].start == start)
        #expect(result[0].end == start)
    }

    // MARK: - averageDurationPerDay Tests

    @Test func averageDurationPerDay_singleDay_returnsCorrectAverage() async {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())

        let durations = [
            PlotDuration(start: startOfDay.addingTimeInterval(0), end: startOfDay.addingTimeInterval(3600), id: UUID()), // 1 hour
            PlotDuration(start: startOfDay.addingTimeInterval(7200), end: startOfDay.addingTimeInterval(10800), id: UUID()) // 1 hour
        ]

        let result = await DataController.averageDurationPerDay(durations)

        // Both durations are on the same day, so total is 2 hours (7200 seconds)
        #expect(result == 7200)
    }

    @Test func averageDurationPerDay_multipleDays_returnsCorrectAverage() async {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        let durations = [
            // Today: 2 hours total
            PlotDuration(start: today.addingTimeInterval(0), end: today.addingTimeInterval(7200), id: UUID()),
            // Yesterday: 4 hours total
            PlotDuration(start: yesterday.addingTimeInterval(0), end: yesterday.addingTimeInterval(14400), id: UUID())
        ]

        let result = await DataController.averageDurationPerDay(durations)

        // Average: (7200 + 14400) / 2 = 10800 seconds (3 hours)
        #expect(result == 10800)
    }

    @Test func averageDurationPerDay_emptyInput_returnsZero() async {
        let result = await DataController.averageDurationPerDay([])
        #expect(result == 0)
    }

    @Test func averageDurationPerDay_differentMonths_groupsCorrectly() async {
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

        let result = await DataController.averageDurationPerDay(durations)

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
