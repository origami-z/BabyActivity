//
//  Milestone.swift
//  BabyActivity
//
//  Milestone model for tracking developmental achievements with photo support
//

import Foundation
import SwiftData

/// Common baby milestones
public enum MilestoneType: String, Equatable, Sendable, Codable, CaseIterable {
    case firstSmile
    case rollOver
    case sitUp
    case crawl
    case stand
    case firstSteps
    case firstWord
    case firstTooth
    case sleepThroughNight
    case firstSolidFood
    case wave
    case clap
    case pointAtObjects
    case walkAlone
    case runAlone
    case other
}

extension MilestoneType: CustomStringConvertible {
    public var description: String {
        switch self {
        case .firstSmile: return "First Smile"
        case .rollOver: return "Roll Over"
        case .sitUp: return "Sit Up"
        case .crawl: return "Crawl"
        case .stand: return "Stand"
        case .firstSteps: return "First Steps"
        case .firstWord: return "First Word"
        case .firstTooth: return "First Tooth"
        case .sleepThroughNight: return "Sleep Through Night"
        case .firstSolidFood: return "First Solid Food"
        case .wave: return "Wave"
        case .clap: return "Clap"
        case .pointAtObjects: return "Point at Objects"
        case .walkAlone: return "Walk Alone"
        case .runAlone: return "Run Alone"
        case .other: return "Other"
        }
    }

    public var icon: String {
        switch self {
        case .firstSmile: return "face.smiling.fill"
        case .rollOver: return "arrow.triangle.2.circlepath"
        case .sitUp: return "figure.seated.side"
        case .crawl: return "figure.crawl"
        case .stand: return "figure.stand"
        case .firstSteps: return "figure.walk"
        case .firstWord: return "bubble.left.fill"
        case .firstTooth: return "mouth.fill"
        case .sleepThroughNight: return "moon.stars.fill"
        case .firstSolidFood: return "fork.knife"
        case .wave: return "hand.wave.fill"
        case .clap: return "hands.clap.fill"
        case .pointAtObjects: return "hand.point.up.left.fill"
        case .walkAlone: return "figure.walk"
        case .runAlone: return "figure.run"
        case .other: return "star.fill"
        }
    }

    /// Expected age range in months (min, max) for reference
    public var expectedAgeMonths: (min: Int, max: Int)? {
        switch self {
        case .firstSmile: return (1, 3)
        case .rollOver: return (4, 6)
        case .sitUp: return (6, 9)
        case .crawl: return (7, 10)
        case .stand: return (9, 12)
        case .firstSteps: return (9, 15)
        case .firstWord: return (12, 18)
        case .firstTooth: return (6, 12)
        case .sleepThroughNight: return (4, 12)
        case .firstSolidFood: return (4, 6)
        case .wave: return (9, 12)
        case .clap: return (9, 12)
        case .pointAtObjects: return (9, 14)
        case .walkAlone: return (12, 18)
        case .runAlone: return (18, 24)
        case .other: return nil
        }
    }
}

@Model
final class Milestone {
    var timestamp: Date
    var milestoneType: MilestoneType
    var customTitle: String?  // For "other" type or custom name
    var notes: String?
    var photoData: Data?  // Photo attachment stored as binary data

    init(milestoneType: MilestoneType, timestamp: Date, customTitle: String? = nil, notes: String? = nil, photoData: Data? = nil) {
        self.timestamp = timestamp
        self.milestoneType = milestoneType
        self.customTitle = customTitle
        self.notes = notes
        self.photoData = photoData
    }

    // MARK: - Display

    var title: String {
        if let custom = customTitle, !custom.isEmpty {
            return custom
        }
        return milestoneType.description
    }

    var shortDisplay: String {
        title
    }

    var image: String {
        milestoneType.icon
    }

    /// Age at milestone in months (requires baby's birth date)
    func ageAtMilestone(birthDate: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.month], from: birthDate, to: timestamp)
        return components.month ?? 0
    }

    /// Checks if milestone was achieved within expected age range
    func isWithinExpectedRange(birthDate: Date) -> Bool? {
        guard let expected = milestoneType.expectedAgeMonths else { return nil }
        let ageMonths = ageAtMilestone(birthDate: birthDate)
        return ageMonths >= expected.min && ageMonths <= expected.max
    }
}
