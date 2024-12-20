//
//  Activity.swift
//  BabyActivity
//
//  Created by Zhihao Cui on 19/12/2024.
//

import Foundation
import SwiftData

public enum ActivityData: Equatable, Sendable, Codable {
    case sleep(endAt: Date)
    case milk(endAt: Date, amount: Int)
    case diaperChange(dirty: Bool)
}


@Model
final class Activity {
    var timestamp: Date
    
    var data: ActivityData
    
    init(timestamp: Date, data: ActivityData) {
        self.timestamp = timestamp
        self.data = data
    }
}

extension Activity {
    var kind: String {
        switch data {
        case .sleep: return "sleep"
        case .milk: return "milk"
        case .diaperChange: return "diaper"
        }
    }
    
    var shortDisplay: String {
        switch data {
        case .sleep(let endAt): return "Sleep \(Duration.seconds(endAt.timeIntervalSince(timestamp)).formatted(.units(allowed: [.minutes, .seconds, .milliseconds], width: .condensedAbbreviated)))"
        case .milk(_, let amount): return "Milk \(amount)ml"
        case .diaperChange(dirty: false): return "Wet diaper"
        case .diaperChange(dirty: true): return "Dirty diaper"
        }
    }
    
    static var sleepImage: String = "zzz"
    static var milkImage: String = "backpack.circle"
    static var wetDiaperImage: String = "toilet"
    static var dirtyDiaperImage: String = "tornado"
    
    var image: String {
        switch data {
        case .sleep: return Activity.sleepImage
        case .milk: return Activity.milkImage
        case .diaperChange(dirty: false): return Activity.wetDiaperImage
        case .diaperChange(dirty: true): return Activity.dirtyDiaperImage
        }
    }
}
