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
        for i in 1...3 {
            let startingTimeInterval = Double(i) * 60 * -60 * 24 * 2 // -2i day
            let hourInterval = Double(i) * 60 * 60
            activities.append(contentsOf: [
                // sleeps
                Activity(kind:.sleep, timestamp: Date().addingTimeInterval(startingTimeInterval - hourInterval), endTimestamp: Date().addingTimeInterval(startingTimeInterval + hourInterval)), // cross-over from previous day
                Activity(kind:.sleep, timestamp: Date().addingTimeInterval(startingTimeInterval + hourInterval * 2), endTimestamp: Date().addingTimeInterval(startingTimeInterval + hourInterval * 3.5)),
                Activity(kind:.sleep, timestamp: Date().addingTimeInterval(startingTimeInterval + hourInterval * 5), endTimestamp: Date().addingTimeInterval(startingTimeInterval + hourInterval * 5.8)),
                Activity(kind:.sleep, timestamp: Date().addingTimeInterval(startingTimeInterval + hourInterval * 9), endTimestamp: Date().addingTimeInterval(startingTimeInterval + hourInterval * 9.6)),
                Activity(kind:.sleep, timestamp: Date().addingTimeInterval(startingTimeInterval + hourInterval * 14), endTimestamp: Date().addingTimeInterval(startingTimeInterval + hourInterval * 15.2)),
                Activity(kind:.sleep, timestamp: Date().addingTimeInterval(startingTimeInterval + hourInterval * 18), endTimestamp: Date().addingTimeInterval(startingTimeInterval + hourInterval * 19.1)),
                Activity(kind:.sleep, timestamp: Date().addingTimeInterval(startingTimeInterval + hourInterval * 22), endTimestamp: Date().addingTimeInterval(startingTimeInterval + hourInterval * 27)), // cross over to next day
                
                // milk
                Activity(kind: .milk, timestamp: Date().addingTimeInterval(startingTimeInterval + hourInterval * 1.5), endTimestamp: Date().addingTimeInterval(startingTimeInterval + hourInterval * 1.9), amount: 30 * i),
                Activity(kind: .milk, timestamp: Date().addingTimeInterval(startingTimeInterval + hourInterval * 6.5), endTimestamp: Date().addingTimeInterval(startingTimeInterval + hourInterval * 7.2), amount: 30 * i),
                Activity(kind: .milk, timestamp: Date().addingTimeInterval(startingTimeInterval + hourInterval * 11.2), endTimestamp: Date().addingTimeInterval(startingTimeInterval + hourInterval * 11.9), amount: 30 * i),
                Activity(kind: .milk, timestamp: Date().addingTimeInterval(startingTimeInterval + hourInterval * 17.1), endTimestamp: Date().addingTimeInterval(startingTimeInterval + hourInterval * 17.8), amount: 30 * i),
                Activity(kind: .milk, timestamp: Date().addingTimeInterval(startingTimeInterval + hourInterval * 20.8), endTimestamp: Date().addingTimeInterval(startingTimeInterval + hourInterval * 21.3), amount: 30 * i),
                
                // diaper
                Activity(kind: .dirtyDiaper, timestamp: Date().addingTimeInterval(startingTimeInterval + hourInterval * 1.1)),
                Activity(kind: .wetDiaper, timestamp: Date().addingTimeInterval(startingTimeInterval + hourInterval * 3.7)),
                Activity(kind: .wetDiaper, timestamp: Date().addingTimeInterval(startingTimeInterval + hourInterval * 6)),
                Activity(kind: .dirtyDiaper, timestamp: Date().addingTimeInterval(startingTimeInterval + hourInterval * 9.9)),
                Activity(kind: .wetDiaper, timestamp: Date().addingTimeInterval(startingTimeInterval + hourInterval * 15.4)),
                Activity(kind: .wetDiaper, timestamp: Date().addingTimeInterval(startingTimeInterval + hourInterval * 19.4))
            ])
        }
        return activities
    }()
    
    // Slice activities into the same day, for calculation and chart
    static func sliceDataToSameDay(sleepActivities: [Activity]) -> [Activity] {
        return []
    }
}
