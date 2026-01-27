//
//  Activity.swift
//  BabyActivity
//
//  Created by Zhihao Cui on 19/12/2024.
//

import Foundation
import SwiftData

public enum ActivityKind: String, Equatable, Sendable, Codable {
    case sleep
    case milk
    case wetDiaper
    case dirtyDiaper
}

extension ActivityKind: CustomStringConvertible {
    public var description: String {
        switch self {
        case .sleep: return "sleep"
        case .milk: return "milk"
        case .wetDiaper: return "wet diaper"
        case .dirtyDiaper: return "dirty diaper"
        }
    }
}



@Model
final class Activity {
    var timestamp: Date
    
    var kind: ActivityKind
    
    // below properties depends on kind above
    var endTimestamp: Date?
    var amount: Int?
    
    init(kind: ActivityKind, timestamp: Date, endTimestamp: Date?, amount: Int?) {
        self.timestamp = timestamp
        self.kind = kind
        self.endTimestamp = endTimestamp
        self.amount = amount
    }
    
    // diaper
    convenience init(kind: ActivityKind, timestamp: Date) {
        self.init(kind: kind, timestamp: timestamp, endTimestamp: nil, amount: nil)
    }
    
    // sleep
    convenience init(kind: ActivityKind, timestamp: Date, endTimestamp: Date) {
        self.init(kind: kind, timestamp: timestamp, endTimestamp: endTimestamp, amount: nil)
    }
    
    // milk
//    convenience init(kind: ActivityKind, timestamp: Date, endTimestamp: Date, amount: Int) {
//        self.init(kind: kind, timestamp: timestamp, endTimestamp: endTimestamp, amount: amount)
//    }
}

extension Activity {
    // MARK: - Validation

    /// Validates that endTimestamp is after timestamp for activities that have duration
    var isValidTimeRange: Bool {
        guard let end = endTimestamp else { return true }
        return end > timestamp
    }

    /// Validates milk amount is within reasonable range (0-500ml)
    var isValidMilkAmount: Bool {
        guard kind == .milk else { return true }
        guard let amt = amount else { return true }
        return amt >= 0 && amt <= 500
    }

    /// Checks all validations for the activity
    var isValid: Bool {
        return isValidTimeRange && isValidMilkAmount
    }

    /// Returns validation error messages if any
    var validationErrors: [String] {
        var errors: [String] = []
        if !isValidTimeRange {
            errors.append("End time must be after start time")
        }
        if !isValidMilkAmount {
            errors.append("Milk amount must be between 0 and 500ml")
        }
        return errors
    }

    // MARK: - Display

    var shortDisplay: String {
        switch kind {
        case .sleep: return "Sleep \(Duration.seconds(endTimestamp?.timeIntervalSince(timestamp) ?? 0).formatted(.units(allowed: [.hours, .minutes], width: .condensedAbbreviated)))"
        case .milk: return "Milk \(amount ?? 0)ml"
        case .wetDiaper: return "Wet diaper"
        case .dirtyDiaper: return "Dirty diaper"
        }
    }
    
    static var sleepImage: String = "zzz"
    static var milkImage: String = "cup.and.saucer.fill"
    static var wetDiaperImage: String = "toilet"
    static var dirtyDiaperImage: String = "tornado"
    
    var image: String {
        switch kind {
        case .sleep: return Activity.sleepImage
        case .milk: return Activity.milkImage
        case .wetDiaper: return Activity.wetDiaperImage
        case .dirtyDiaper: return Activity.dirtyDiaperImage
        }
    }
}
