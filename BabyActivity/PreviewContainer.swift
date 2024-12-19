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
                container.mainContext.insert(Activity(timestamp: Date().addingTimeInterval(Double(i) * 60 * -60), data: ActivityData.sleep(endAt: Date().addingTimeInterval(Double(1) * 60 * -60) + 10)))
                container.mainContext.insert(Activity(timestamp: Date().addingTimeInterval(Double(i) * 60 * -60), data: ActivityData.milk(endAt: Date().addingTimeInterval(Double(1) * 60 * -60) + 10, amount: 30 * i)))
                container.mainContext.insert(Activity(timestamp: Date().addingTimeInterval(Double(i) * 60 * -60), data: ActivityData.diaperChange(dirty: i%2 == 0)))
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
