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
        let groupedByDay = Dictionary(grouping: durations, by: { Calendar.current.dateComponents([.day], from: $0.start).day! })
        let averageDurationPerDay = groupedByDay.values.map { $0.reduce(0) { $0 + $1.end.timeIntervalSince($1.start)}  }
        return averageDurationPerDay.mean()
    }
}

extension Array where Element: FloatingPoint {
    
    func mean() -> Element {
        reduce(0, +) / Element(count)
    }
}

struct PlotDuration:Identifiable {
    var start: Date
    var end: Date
    var id: UUID
}
