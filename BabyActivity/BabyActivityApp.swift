//
//  BabyActivityApp.swift
//  BabyActivity
//
//  Created by Zhihao Cui on 19/12/2024.
//

import SwiftUI
import SwiftData
import UserNotifications

@main
struct BabyActivityApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var quickActionService = QuickActionService.shared

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Activity.self,
            GrowthMeasurement.self,
            Milestone.self,
            Baby.self,
            FamilyMember.self,
        ])

        // Configure CloudKit-backed store for iCloud sync
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .automatic
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(quickActionService)
        }
        .modelContainer(sharedModelContainer)
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background {
                updateDynamicQuickActions()
            }
        }
    }

    private func updateDynamicQuickActions() {
        let context = sharedModelContainer.mainContext
        let descriptor = FetchDescriptor<Activity>()
        let activities = (try? context.fetch(descriptor)) ?? []
        let topKinds = QuickActionService.topActivityKinds(from: activities)
        quickActionService.updateQuickActions(topKinds: topKinds)
    }
}

// MARK: - App Delegate for Notification Handling

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Set the notification center delegate
        UNUserNotificationCenter.current().delegate = NotificationService.shared

        // Handle quick action from cold launch
        if let shortcutItem = launchOptions?[.shortcutItem] as? UIApplicationShortcutItem {
            QuickActionService.shared.handleShortcutItem(shortcutItem)
        }

        // Set default quick actions on first launch
        if application.shortcutItems?.isEmpty ?? true {
            QuickActionService.shared.updateQuickActions(topKinds: [])
        }

        return true
    }

    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        let config = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        config.delegateClass = SceneDelegate.self
        return config
    }
}

// MARK: - Scene Delegate for Quick Action Handling

class SceneDelegate: NSObject, UIWindowSceneDelegate {
    func windowScene(
        _ windowScene: UIWindowScene,
        performActionFor shortcutItem: UIApplicationShortcutItem,
        completionHandler: @escaping (Bool) -> Void
    ) {
        let handled = QuickActionService.shared.handleShortcutItem(shortcutItem)
        completionHandler(handled)
    }
}
