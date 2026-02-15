//
//  QuickActionService.swift
//  BabyActivity
//
//  Created on 2026-02-15.
//

import UIKit

/// Manages iOS Home Screen quick actions (3D Touch / long-press shortcuts)
@MainActor
class QuickActionService: ObservableObject {
    static let shared = QuickActionService()

    /// The activity kind selected via a quick action, if any
    @Published var pendingActionKind: ActivityKind?

    /// The shortcut item type prefix used for all quick actions
    static let shortcutTypePrefix = "com.babyactivity.quickaction."

    /// Default quick actions shown when no usage data is available
    static let defaultQuickActionKinds: [ActivityKind] = [
        .milk, .wetDiaper, .dirtyDiaper, .sleep
    ]

    /// Configures the app's dynamic Home Screen quick actions.
    /// Call this when the app moves to the background so iOS picks up the updated shortcuts.
    /// - Parameter topKinds: Activity kinds ordered by most-used first. Up to 4 will be used.
    func updateQuickActions(topKinds: [ActivityKind]) {
        let kinds = topKinds.isEmpty ? Self.defaultQuickActionKinds : Array(topKinds.prefix(4))
        UIApplication.shared.shortcutItems = kinds.map { Self.shortcutItem(for: $0) }
    }

    /// Handles an incoming shortcut item. Returns `true` if it was recognized.
    @discardableResult
    func handleShortcutItem(_ shortcutItem: UIApplicationShortcutItem) -> Bool {
        guard let kind = Self.activityKind(from: shortcutItem) else { return false }
        pendingActionKind = kind
        return true
    }

    // MARK: - Helpers

    /// Creates a `UIApplicationShortcutItem` for the given activity kind.
    static func shortcutItem(for kind: ActivityKind) -> UIApplicationShortcutItem {
        UIApplicationShortcutItem(
            type: shortcutTypePrefix + kind.rawValue,
            localizedTitle: shortcutTitle(for: kind),
            localizedSubtitle: nil,
            icon: shortcutIcon(for: kind)
        )
    }

    /// Extracts an `ActivityKind` from a shortcut item, if the type matches.
    static func activityKind(from shortcutItem: UIApplicationShortcutItem) -> ActivityKind? {
        guard shortcutItem.type.hasPrefix(shortcutTypePrefix) else { return nil }
        let rawValue = String(shortcutItem.type.dropFirst(shortcutTypePrefix.count))
        return ActivityKind(rawValue: rawValue)
    }

    /// User-facing title for the quick action.
    static func shortcutTitle(for kind: ActivityKind) -> String {
        switch kind {
        case .sleep: return "Log Sleep"
        case .milk: return "Log Milk"
        case .wetDiaper: return "Log Wet Diaper"
        case .dirtyDiaper: return "Log Dirty Diaper"
        case .solidFood: return "Log Solid Food"
        case .tummyTime: return "Log Tummy Time"
        case .bathTime: return "Log Bath Time"
        case .medicine: return "Log Medicine"
        }
    }

    /// SF Symbol icon for the quick action.
    static func shortcutIcon(for kind: ActivityKind) -> UIApplicationShortcutIcon {
        switch kind {
        case .sleep: return UIApplicationShortcutIcon(systemImageName: Activity.sleepImage)
        case .milk: return UIApplicationShortcutIcon(systemImageName: Activity.milkImage)
        case .wetDiaper: return UIApplicationShortcutIcon(systemImageName: Activity.wetDiaperImage)
        case .dirtyDiaper: return UIApplicationShortcutIcon(systemImageName: Activity.dirtyDiaperImage)
        case .solidFood: return UIApplicationShortcutIcon(systemImageName: Activity.solidFoodImage)
        case .tummyTime: return UIApplicationShortcutIcon(systemImageName: Activity.tummyTimeImage)
        case .bathTime: return UIApplicationShortcutIcon(systemImageName: Activity.bathTimeImage)
        case .medicine: return UIApplicationShortcutIcon(systemImageName: Activity.medicineImage)
        }
    }

    /// Computes the top activity kinds by frequency from a list of activities.
    /// Returns up to `limit` kinds, most frequent first.
    static func topActivityKinds(from activities: [Activity], limit: Int = 4) -> [ActivityKind] {
        guard !activities.isEmpty else { return defaultQuickActionKinds }

        var counts: [ActivityKind: Int] = [:]
        for activity in activities {
            counts[activity.kind, default: 0] += 1
        }

        let sorted = counts.sorted { $0.value > $1.value }
        let topKinds = sorted.prefix(limit).map { $0.key }

        return topKinds.isEmpty ? defaultQuickActionKinds : Array(topKinds)
    }
}
