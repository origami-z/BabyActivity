//
//  Growth.swift
//  BabyActivity
//
//  Growth measurements model for tracking weight, height, and head circumference
//

import Foundation
import SwiftData

/// Types of growth measurements
public enum GrowthMeasurementType: String, Equatable, Sendable, Codable, CaseIterable {
    case weight
    case height
    case headCircumference
}

extension GrowthMeasurementType: CustomStringConvertible {
    public var description: String {
        switch self {
        case .weight: return "Weight"
        case .height: return "Height"
        case .headCircumference: return "Head Circumference"
        }
    }

    public var unit: String {
        switch self {
        case .weight: return "kg"
        case .height: return "cm"
        case .headCircumference: return "cm"
        }
    }

    public var icon: String {
        switch self {
        case .weight: return "scalemass.fill"
        case .height: return "ruler.fill"
        case .headCircumference: return "circle.dashed"
        }
    }
}

@Model
final class GrowthMeasurement {
    var timestamp: Date
    var measurementType: GrowthMeasurementType
    var value: Double  // Weight in kg, height/head in cm
    var notes: String?

    init(measurementType: GrowthMeasurementType, timestamp: Date, value: Double, notes: String? = nil) {
        self.timestamp = timestamp
        self.measurementType = measurementType
        self.value = value
        self.notes = notes
    }

    // MARK: - Display

    var shortDisplay: String {
        let formattedValue = String(format: "%.1f", value)
        return "\(measurementType.description): \(formattedValue) \(measurementType.unit)"
    }

    var image: String {
        measurementType.icon
    }
}

// MARK: - Validation

extension GrowthMeasurement {
    /// Validates that the measurement value is within reasonable range
    var isValid: Bool {
        switch measurementType {
        case .weight:
            return value >= 0 && value <= 30  // 0-30 kg reasonable for babies/toddlers
        case .height:
            return value >= 20 && value <= 150  // 20-150 cm
        case .headCircumference:
            return value >= 20 && value <= 60  // 20-60 cm
        }
    }

    var validationErrors: [String] {
        var errors: [String] = []
        if !isValid {
            switch measurementType {
            case .weight:
                errors.append("Weight must be between 0 and 30 kg")
            case .height:
                errors.append("Height must be between 20 and 150 cm")
            case .headCircumference:
                errors.append("Head circumference must be between 20 and 60 cm")
            }
        }
        return errors
    }
}
