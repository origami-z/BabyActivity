//
//  BabyActivityApp.swift
//  BabyActivity
//
//  Created by Zhihao Cui on 19/12/2024.
//

import SwiftUI

@main
struct BabyActivityApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            MainView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
