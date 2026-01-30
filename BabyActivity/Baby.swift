//
//  Baby.swift
//  BabyActivity
//
//  Baby profile model with iCloud family sharing support
//

import Foundation
import SwiftData

/// Permission levels for family sharing
public enum PermissionLevel: String, Equatable, Sendable, Codable, CaseIterable {
    case admin       // Full access, manage members
    case caregiver   // Add/edit activities
    case viewer      // Read-only access
}

extension PermissionLevel: CustomStringConvertible {
    public var description: String {
        switch self {
        case .admin: return "Admin"
        case .caregiver: return "Caregiver"
        case .viewer: return "Viewer"
        }
    }

    public var detailedDescription: String {
        switch self {
        case .admin: return "Full access and can manage family members"
        case .caregiver: return "Can add and edit activities"
        case .viewer: return "Can only view activities"
        }
    }

    public var icon: String {
        switch self {
        case .admin: return "crown.fill"
        case .caregiver: return "person.badge.plus"
        case .viewer: return "eye.fill"
        }
    }
}

/// Represents a family member with access to the baby's data
@Model
final class FamilyMember {
    var id: UUID
    var cloudKitUserID: String       // iCloud user identifier
    var displayName: String
    var permission: PermissionLevel
    var addedDate: Date
    var lastSyncDate: Date?

    @Relationship(inverse: \Baby.sharedWith)
    var baby: Baby?

    init(cloudKitUserID: String, displayName: String, permission: PermissionLevel) {
        self.id = UUID()
        self.cloudKitUserID = cloudKitUserID
        self.displayName = displayName
        self.permission = permission
        self.addedDate = Date()
    }

    /// Checks if member has write access (admin or caregiver)
    var canEdit: Bool {
        permission == .admin || permission == .caregiver
    }

    /// Checks if member can manage other members
    var canManageMembers: Bool {
        permission == .admin
    }
}

/// Represents a baby profile that can be shared with family members
@Model
final class Baby {
    var id: UUID
    var name: String
    var birthDate: Date
    var photoData: Data?
    var createdDate: Date
    var lastModified: Date
    var ownerCloudKitID: String?     // iCloud ID of the profile creator

    @Relationship(deleteRule: .cascade)
    var sharedWith: [FamilyMember] = []

    @Relationship(deleteRule: .cascade)
    var activities: [Activity] = []

    @Relationship(deleteRule: .cascade)
    var growthMeasurements: [GrowthMeasurement] = []

    @Relationship(deleteRule: .cascade)
    var milestones: [Milestone] = []

    init(name: String, birthDate: Date, photoData: Data? = nil, ownerCloudKitID: String? = nil) {
        self.id = UUID()
        self.name = name
        self.birthDate = birthDate
        self.photoData = photoData
        self.createdDate = Date()
        self.lastModified = Date()
        self.ownerCloudKitID = ownerCloudKitID
    }

    // MARK: - Display

    var shortDisplay: String {
        name
    }

    /// Age of the baby in months
    var ageInMonths: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.month], from: birthDate, to: Date())
        return components.month ?? 0
    }

    /// Age of the baby formatted as string (e.g., "3 months" or "1 year 2 months")
    var ageDisplay: String {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: birthDate, to: Date())

        let years = components.year ?? 0
        let months = components.month ?? 0

        if years == 0 {
            return months == 1 ? "1 month" : "\(months) months"
        } else if years == 1 && months == 0 {
            return "1 year"
        } else if years == 1 {
            return months == 1 ? "1 year 1 month" : "1 year \(months) months"
        } else if months == 0 {
            return "\(years) years"
        } else {
            return months == 1 ? "\(years) years 1 month" : "\(years) years \(months) months"
        }
    }

    // MARK: - Family Sharing

    /// Adds a family member with specified permission
    func addFamilyMember(cloudKitUserID: String, displayName: String, permission: PermissionLevel) -> FamilyMember {
        let member = FamilyMember(cloudKitUserID: cloudKitUserID, displayName: displayName, permission: permission)
        sharedWith.append(member)
        lastModified = Date()
        return member
    }

    /// Removes a family member by their CloudKit ID
    func removeFamilyMember(cloudKitUserID: String) {
        sharedWith.removeAll { $0.cloudKitUserID == cloudKitUserID }
        lastModified = Date()
    }

    /// Updates permission for a family member
    func updatePermission(for cloudKitUserID: String, to permission: PermissionLevel) {
        if let member = sharedWith.first(where: { $0.cloudKitUserID == cloudKitUserID }) {
            member.permission = permission
            lastModified = Date()
        }
    }

    /// Gets permission level for a CloudKit user ID
    func permission(for cloudKitUserID: String) -> PermissionLevel? {
        // Owner has admin access
        if ownerCloudKitID == cloudKitUserID {
            return .admin
        }
        return sharedWith.first { $0.cloudKitUserID == cloudKitUserID }?.permission
    }

    /// Checks if a user has at least the specified permission level
    func hasPermission(_ requiredLevel: PermissionLevel, for cloudKitUserID: String) -> Bool {
        guard let userPermission = permission(for: cloudKitUserID) else { return false }

        switch requiredLevel {
        case .viewer:
            return true  // All levels have viewer access
        case .caregiver:
            return userPermission == .caregiver || userPermission == .admin
        case .admin:
            return userPermission == .admin
        }
    }

    /// List of all CloudKit user IDs with access
    var allUserIDs: [String] {
        var ids = sharedWith.map { $0.cloudKitUserID }
        if let ownerID = ownerCloudKitID {
            ids.insert(ownerID, at: 0)
        }
        return ids
    }
}

// MARK: - Validation

extension Baby {
    /// Validates that name is not empty
    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var validationErrors: [String] {
        var errors: [String] = []
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append("Name cannot be empty")
        }
        return errors
    }
}
