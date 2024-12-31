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
    var shortDisplay: String {
        switch kind {
        case .sleep: return "Sleep \(Duration.seconds(endTimestamp?.timeIntervalSince(timestamp) ?? 0).formatted(.units(allowed: [.hours, .minutes], width: .condensedAbbreviated)))"
        case .milk: return "Milk \(amount ?? 0)ml"
        case .wetDiaper: return "Wet diaper"
        case .dirtyDiaper: return "Dirty diaper"
        }
    }
    
    static var sleepImage: String = "zzz"
    static var milkImage: String = "backpack.circle"
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
