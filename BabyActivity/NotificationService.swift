//
//  NotificationService.swift
//  BabyActivity
//
//  Handles local notifications for smart reminders
//

import Foundation
import UserNotifications
import SwiftUI

/// Service for managing local notifications
@MainActor
class NotificationService: NSObject, ObservableObject {
    static let shared = NotificationService()

    @Published var isAuthorized: Bool = false
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published var scheduledNotifications: [UNNotificationRequest] = []

    private let notificationCenter = UNUserNotificationCenter.current()

    // Notification category identifiers
    static let activityReminderCategory = "ACTIVITY_REMINDER"

    // Notification action identifiers
    static let logActivityAction = "LOG_ACTIVITY"
    static let snoozeAction = "SNOOZE"
    static let dismissAction = "DISMISS"

    override init() {
        super.init()
        Task {
            await setupNotificationCategories()
            await checkAuthorizationStatus()
        }
    }

    // MARK: - Authorization

    /// Request notification permissions from the user
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(
                options: [.alert, .sound, .badge]
            )
            await MainActor.run {
                self.isAuthorized = granted
            }
            await checkAuthorizationStatus()
            return granted
        } catch {
            print("Error requesting notification authorization: \(error)")
            return false
        }
    }

    /// Check current authorization status
    func checkAuthorizationStatus() async {
        let settings = await notificationCenter.notificationSettings()
        await MainActor.run {
            self.authorizationStatus = settings.authorizationStatus
            self.isAuthorized = settings.authorizationStatus == .authorized
        }
    }

    /// Open settings app for the user to change notification permissions
    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    // MARK: - Notification Categories & Actions

    /// Setup notification categories with actions
    private func setupNotificationCategories() async {
        let logAction = UNNotificationAction(
            identifier: Self.logActivityAction,
            title: "Log Activity",
            options: [.foreground]
        )

        let snoozeAction = UNNotificationAction(
            identifier: Self.snoozeAction,
            title: "Snooze 15 min",
            options: []
        )

        let dismissAction = UNNotificationAction(
            identifier: Self.dismissAction,
            title: "Dismiss",
            options: [.destructive]
        )

        let activityCategory = UNNotificationCategory(
            identifier: Self.activityReminderCategory,
            actions: [logAction, snoozeAction, dismissAction],
            intentIdentifiers: [],
            options: []
        )

        notificationCenter.setNotificationCategories([activityCategory])
    }

    // MARK: - Schedule Notifications

    /// Schedule a reminder notification
    func scheduleReminder(_ reminder: ScheduledReminder) async throws {
        guard isAuthorized else {
            throw NotificationError.notAuthorized
        }

        let content = UNMutableNotificationContent()
        content.title = "BabyActivity Reminder"
        content.subtitle = reminder.activityKind.description.capitalized
        content.body = reminder.message
        content.sound = reminder.priority.notificationSound ? .default : nil
        content.categoryIdentifier = Self.activityReminderCategory

        // Add user info for handling the notification action
        content.userInfo = [
            "activityKind": reminder.activityKind.rawValue,
            "reminderId": reminder.id.uuidString
        ]

        // Create trigger for the scheduled time
        let triggerDate = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: reminder.scheduledTime
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)

        let request = UNNotificationRequest(
            identifier: reminder.id.uuidString,
            content: content,
            trigger: trigger
        )

        try await notificationCenter.add(request)
        await refreshScheduledNotifications()
    }

    /// Schedule multiple reminders
    func scheduleReminders(_ reminders: [ScheduledReminder]) async {
        // First, cancel any existing reminders
        await cancelAllReminders()

        for reminder in reminders {
            do {
                try await scheduleReminder(reminder)
            } catch {
                print("Error scheduling reminder: \(error)")
            }
        }
    }

    /// Cancel a specific reminder
    func cancelReminder(id: UUID) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [id.uuidString])
        Task {
            await refreshScheduledNotifications()
        }
    }

    /// Cancel all scheduled reminders
    func cancelAllReminders() async {
        notificationCenter.removeAllPendingNotificationRequests()
        await refreshScheduledNotifications()
    }

    /// Refresh the list of scheduled notifications
    func refreshScheduledNotifications() async {
        let pending = await notificationCenter.pendingNotificationRequests()
        await MainActor.run {
            self.scheduledNotifications = pending
        }
    }

    // MARK: - Snooze

    /// Snooze a reminder by a specified number of minutes
    func snoozeReminder(originalReminder: ScheduledReminder, minutes: Int = 15) async throws {
        let snoozedTime = Date().addingTimeInterval(Double(minutes * 60))

        let snoozedReminder = ScheduledReminder(
            activityKind: originalReminder.activityKind,
            scheduledTime: snoozedTime,
            message: originalReminder.message,
            isRepeating: false,
            priority: originalReminder.priority
        )

        try await scheduleReminder(snoozedReminder)
    }

    // MARK: - Quick Notifications

    /// Send an immediate notification (for testing)
    func sendTestNotification() async throws {
        guard isAuthorized else {
            throw NotificationError.notAuthorized
        }

        let content = UNMutableNotificationContent()
        content.title = "Test Notification"
        content.body = "Smart reminders are working correctly!"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )

        try await notificationCenter.add(request)
    }

    // MARK: - Badge Management

    /// Update the app badge count
    func updateBadgeCount(_ count: Int) async {
        do {
            try await notificationCenter.setBadgeCount(count)
        } catch {
            print("Error updating badge count: \(error)")
        }
    }

    /// Clear the app badge
    func clearBadge() async {
        await updateBadgeCount(0)
    }
}

// MARK: - Notification Errors

enum NotificationError: LocalizedError {
    case notAuthorized
    case schedulingFailed
    case invalidDate

    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Notification permissions not granted. Please enable notifications in Settings."
        case .schedulingFailed:
            return "Failed to schedule the notification."
        case .invalidDate:
            return "Invalid date for scheduling notification."
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationService: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        // Show notification even when app is in foreground
        return [.banner, .sound, .badge]
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let userInfo = response.notification.request.content.userInfo
        let actionIdentifier = response.actionIdentifier

        // Get activity kind from user info
        guard let activityKindRaw = userInfo["activityKind"] as? String,
              let activityKind = ActivityKind(rawValue: activityKindRaw) else {
            return
        }

        switch actionIdentifier {
        case Self.logActivityAction:
            // Post notification to open the app and log activity
            await MainActor.run {
                NotificationCenter.default.post(
                    name: .logActivityFromNotification,
                    object: nil,
                    userInfo: ["activityKind": activityKind]
                )
            }

        case Self.snoozeAction:
            // Snooze the reminder
            if let reminderIdString = userInfo["reminderId"] as? String,
               let reminderId = UUID(uuidString: reminderIdString) {
                let originalReminder = ScheduledReminder(
                    id: reminderId,
                    activityKind: activityKind,
                    scheduledTime: Date(),
                    message: response.notification.request.content.body,
                    isRepeating: false,
                    priority: .medium
                )
                do {
                    try await self.snoozeReminder(originalReminder: originalReminder)
                } catch {
                    print("Error snoozing reminder: \(error)")
                }
            }

        case Self.dismissAction:
            // Just dismiss, nothing to do
            break

        default:
            // Default tap - open app
            await MainActor.run {
                NotificationCenter.default.post(
                    name: .logActivityFromNotification,
                    object: nil,
                    userInfo: ["activityKind": activityKind]
                )
            }
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let logActivityFromNotification = Notification.Name("logActivityFromNotification")
}
