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

            for i in 1...3 {
                let startingTimeInterval = Double(i) * 60 * -60 * 24 // -1 day
                let hourInterval = Double(i) * 60 * 60
                
                // sleeps
                container.mainContext.insert(Activity(timestamp: Date().addingTimeInterval(startingTimeInterval - hourInterval), data: ActivityData.sleep(endAt: Date().addingTimeInterval(startingTimeInterval + hourInterval))))
                container.mainContext.insert(Activity(timestamp: Date().addingTimeInterval(startingTimeInterval + hourInterval * 2), data: ActivityData.sleep(endAt: Date().addingTimeInterval(startingTimeInterval + hourInterval * 2.5))))
                container.mainContext.insert(Activity(timestamp: Date().addingTimeInterval(startingTimeInterval + hourInterval * 5), data: ActivityData.sleep(endAt: Date().addingTimeInterval(startingTimeInterval + hourInterval * 5.8))))
                container.mainContext.insert(Activity(timestamp: Date().addingTimeInterval(startingTimeInterval + hourInterval * 9), data: ActivityData.sleep(endAt: Date().addingTimeInterval(startingTimeInterval + hourInterval * 9.6))))
                container.mainContext.insert(Activity(timestamp: Date().addingTimeInterval(startingTimeInterval + hourInterval * 14), data: ActivityData.sleep(endAt: Date().addingTimeInterval(startingTimeInterval + hourInterval * 15.2))))
                container.mainContext.insert(Activity(timestamp: Date().addingTimeInterval(startingTimeInterval + hourInterval * 18), data: ActivityData.sleep(endAt: Date().addingTimeInterval(startingTimeInterval + hourInterval * 19.1))))
                container.mainContext.insert(Activity(timestamp: Date().addingTimeInterval(startingTimeInterval + hourInterval * 22), data: ActivityData.sleep(endAt: Date().addingTimeInterval(startingTimeInterval + hourInterval * 23.9))))
                
                // milk
                container.mainContext.insert(Activity(timestamp: Date().addingTimeInterval(startingTimeInterval + hourInterval * 3.6), data: ActivityData.milk(endAt: Date().addingTimeInterval(startingTimeInterval + hourInterval * 4.2), amount: 30 * i)))
                container.mainContext.insert(Activity(timestamp: Date().addingTimeInterval(startingTimeInterval + hourInterval * 5.6), data: ActivityData.milk(endAt: Date().addingTimeInterval(startingTimeInterval + hourInterval * 6.2), amount: 30 * i)))
                container.mainContext.insert(Activity(timestamp: Date().addingTimeInterval(startingTimeInterval + hourInterval * 8.6), data: ActivityData.milk(endAt: Date().addingTimeInterval(startingTimeInterval + hourInterval * 9.2), amount: 30 * i)))
                container.mainContext.insert(Activity(timestamp: Date().addingTimeInterval(startingTimeInterval + hourInterval * 13.6), data: ActivityData.milk(endAt: Date().addingTimeInterval(startingTimeInterval + hourInterval * 14.2), amount: 30 * i)))
                
                // diaper
                container.mainContext.insert(Activity(timestamp: Date().addingTimeInterval(startingTimeInterval + hourInterval * 4), data: ActivityData.diaperChange(dirty: i%2 == 0)))
                container.mainContext.insert(Activity(timestamp: Date().addingTimeInterval(startingTimeInterval + hourInterval * 6), data: ActivityData.diaperChange(dirty: i%2 == 1)))
                container.mainContext.insert(Activity(timestamp: Date().addingTimeInterval(startingTimeInterval + hourInterval * 8), data: ActivityData.diaperChange(dirty: i%2 == 1)))
                container.mainContext.insert(Activity(timestamp: Date().addingTimeInterval(startingTimeInterval + hourInterval * 9), data: ActivityData.diaperChange(dirty: i%2 == 0)))
            }

            return container
        } catch {
            fatalError("Failed to create model container for previewing: \(error.localizedDescription)")
        }
    }()
    
    
    static let sleepAcitivity = Activity(timestamp: Date().addingTimeInterval(Double(1) * 60 * -60), data: ActivityData.sleep(endAt: Date().addingTimeInterval(Double(1) * 60 * -60) + 10*60))
    static let milkAcitivity = Activity(timestamp: Date().addingTimeInterval(Double(1) * 60 * -60), data: ActivityData.milk(endAt: Date().addingTimeInterval(Double(1) * 60 * -60) + 10*60, amount: 50))
    static let diaperAcitivity = Activity(timestamp: Date().addingTimeInterval(Double(1) * 60 * -60), data: ActivityData.diaperChange(dirty: false))
}
