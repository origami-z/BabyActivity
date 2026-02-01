//
//  Activity.swift
//  BabyActivity
//
//  Created by Zhihao Cui on 19/12/2024.
//

import Foundation
import SwiftData

public enum ActivityKind: String, Equatable, Sendable, Codable, CaseIterable {
    case sleep
    case milk
    case wetDiaper
    case dirtyDiaper
    case solidFood
    case tummyTime
    case bathTime
    case medicine
}

extension ActivityKind: CustomStringConvertible {
    public var description: String {
        switch self {
        case .sleep: return "sleep"
        case .milk: return "milk"
        case .wetDiaper: return "wet diaper"
        case .dirtyDiaper: return "dirty diaper"
        case .solidFood: return "solid food"
        case .tummyTime: return "tummy time"
        case .bathTime: return "bath time"
        case .medicine: return "medicine"
        }
    }
}



@Model
final class Activity {
    var timestamp: Date

    var kind: ActivityKind

    // below properties depends on kind above
    var endTimestamp: Date?
    var amount: Int?  // milk amount in ml

    // Solid food properties
    var foodType: String?
    var reactions: String?  // allergen/reaction notes

    // Medicine properties
    var medicineName: String?
    var dosage: String?

    // General notes for any activity
    var notes: String?

    // iCloud sync and family sharing fields
    var contributorId: String?       // iCloud user identifier who logged this
    var contributorName: String?     // Display name of contributor
    var lastModified: Date?          // For sync conflict resolution

    // Relationship to Baby profile
    @Relationship(inverse: \Baby.activities)
    var baby: Baby?

    init(kind: ActivityKind, timestamp: Date, endTimestamp: Date?, amount: Int?,
         foodType: String? = nil, reactions: String? = nil,
         medicineName: String? = nil, dosage: String? = nil, notes: String? = nil,
         contributorId: String? = nil, contributorName: String? = nil) {
        self.timestamp = timestamp
        self.kind = kind
        self.endTimestamp = endTimestamp
        self.amount = amount
        self.foodType = foodType
        self.reactions = reactions
        self.medicineName = medicineName
        self.dosage = dosage
        self.notes = notes
        self.contributorId = contributorId
        self.contributorName = contributorName
        self.lastModified = Date()
    }

    // Simple timestamp activities (diaper, bath)
    convenience init(kind: ActivityKind, timestamp: Date) {
        self.init(kind: kind, timestamp: timestamp, endTimestamp: nil, amount: nil)
    }

    // Duration activities (sleep, tummy time)
    convenience init(kind: ActivityKind, timestamp: Date, endTimestamp: Date) {
        self.init(kind: kind, timestamp: timestamp, endTimestamp: endTimestamp, amount: nil)
    }

    // Solid food
    convenience init(kind: ActivityKind, timestamp: Date, foodType: String, reactions: String? = nil) {
        self.init(kind: kind, timestamp: timestamp, endTimestamp: nil, amount: nil,
                  foodType: foodType, reactions: reactions)
    }

    // Medicine
    convenience init(kind: ActivityKind, timestamp: Date, medicineName: String, dosage: String?) {
        self.init(kind: kind, timestamp: timestamp, endTimestamp: nil, amount: nil,
                  medicineName: medicineName, dosage: dosage)
    }
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
        case .sleep:
            return "Sleep \(Duration.seconds(endTimestamp?.timeIntervalSince(timestamp) ?? 0).formatted(.units(allowed: [.hours, .minutes], width: .condensedAbbreviated)))"
        case .milk:
            return "Milk \(amount ?? 0)ml"
        case .wetDiaper:
            return "Wet diaper"
        case .dirtyDiaper:
            return "Dirty diaper"
        case .solidFood:
            return "Food: \(foodType ?? "Unknown")"
        case .tummyTime:
            return "Tummy \(Duration.seconds(endTimestamp?.timeIntervalSince(timestamp) ?? 0).formatted(.units(allowed: [.hours, .minutes], width: .condensedAbbreviated)))"
        case .bathTime:
            return "Bath time"
        case .medicine:
            if let name = medicineName {
                return "Medicine: \(name)"
            }
            return "Medicine"
        }
    }

    static var sleepImage: String = "zzz"
    static var milkImage: String = "cup.and.saucer.fill"
    static var wetDiaperImage: String = "toilet"
    static var dirtyDiaperImage: String = "tornado"
    static var solidFoodImage: String = "fork.knife"
    static var tummyTimeImage: String = "figure.child"
    static var bathTimeImage: String = "bathtub.fill"
    static var medicineImage: String = "cross.case.fill"

    var image: String {
        switch kind {
        case .sleep: return Activity.sleepImage
        case .milk: return Activity.milkImage
        case .wetDiaper: return Activity.wetDiaperImage
        case .dirtyDiaper: return Activity.dirtyDiaperImage
        case .solidFood: return Activity.solidFoodImage
        case .tummyTime: return Activity.tummyTimeImage
        case .bathTime: return Activity.bathTimeImage
        case .medicine: return Activity.medicineImage
        }
    }
}
