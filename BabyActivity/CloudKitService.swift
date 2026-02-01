//
//  CloudKitService.swift
//  BabyActivity
//
//  Service for managing iCloud and CloudKit operations
//

import Foundation
import CloudKit
import SwiftUI

/// Service for managing iCloud and CloudKit operations
@MainActor
class CloudKitService: ObservableObject {
    static let shared = CloudKitService()

    @Published var isSignedIn: Bool = false
    @Published var currentUserID: String?
    @Published var currentUserName: String?
    @Published var accountStatus: CKAccountStatus = .couldNotDetermine
    @Published var errorMessage: String?

    private let container: CKContainer

    private init() {
        self.container = CKContainer.default()
        Task {
            await checkAccountStatus()
        }
    }

    // MARK: - Account Status

    /// Checks the current iCloud account status
    func checkAccountStatus() async {
        do {
            let status = try await container.accountStatus()
            self.accountStatus = status
            self.isSignedIn = (status == .available)

            if status == .available {
                await fetchCurrentUserInfo()
            } else {
                self.currentUserID = nil
                self.currentUserName = nil
                self.errorMessage = accountStatusMessage(for: status)
            }
        } catch {
            self.isSignedIn = false
            self.errorMessage = error.localizedDescription
        }
    }

    /// Fetches the current iCloud user's ID and name
    func fetchCurrentUserInfo() async {
        do {
            let recordID = try await container.userRecordID()
            self.currentUserID = recordID.recordName
            // Note: userIdentity(forUserRecordID:) was deprecated in iOS 17.
            // We use "Me" as the default display name.
            self.currentUserName = "Me"
            self.errorMessage = nil
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }

    // MARK: - Sharing

    /// Creates a CKShare for sharing a baby profile
    func createShare(for baby: Baby) async throws -> CKShare {
        let privateDatabase = container.privateCloudDatabase
        let recordZone = CKRecordZone(zoneName: "com.apple.coredata.cloudkit.zone")

        // Create a share with the baby as the root record
        let share = CKShare(recordZoneID: recordZone.zoneID)
        share[CKShare.SystemFieldKey.title] = "\(baby.name)'s Profile" as CKRecordValue
        share.publicPermission = .none

        // Save the share to CloudKit
        let operation = CKModifyRecordsOperation(recordsToSave: [share], recordIDsToDelete: nil)
        operation.savePolicy = .changedKeys

        return try await withCheckedThrowingContinuation { continuation in
            operation.modifyRecordsResultBlock = { result in
                switch result {
                case .success:
                    continuation.resume(returning: share)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            privateDatabase.add(operation)
        }
    }

    /// Note: User identity lookup APIs were removed in iOS 17+.
    /// For sharing, use CKShare-based flows instead.
    /// See: https://developer.apple.com/documentation/cloudkit/shared_records

    // MARK: - Sync Status

    /// Monitor sync status changes
    func monitorSyncStatus() {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name.CKAccountChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                await self?.checkAccountStatus()
            }
        }
    }

    // MARK: - Helpers

    private func accountStatusMessage(for status: CKAccountStatus) -> String {
        switch status {
        case .couldNotDetermine:
            return "Unable to determine iCloud status"
        case .available:
            return ""
        case .restricted:
            return "iCloud is restricted on this device"
        case .noAccount:
            return "Please sign in to iCloud in Settings"
        case .temporarilyUnavailable:
            return "iCloud is temporarily unavailable"
        @unknown default:
            return "Unknown iCloud status"
        }
    }

    /// Returns the contributor info for new activities
    var contributorInfo: (id: String?, name: String?) {
        (currentUserID, currentUserName)
    }
}

// MARK: - Sync Status View

/// A view that displays the current iCloud sync status
struct CloudSyncStatusView: View {
    @ObservedObject private var cloudKit = CloudKitService.shared

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: statusIcon)
                .foregroundColor(statusColor)

            VStack(alignment: .leading, spacing: 2) {
                Text(statusTitle)
                    .font(.subheadline)
                    .fontWeight(.medium)

                if let error = cloudKit.errorMessage, !error.isEmpty {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            if cloudKit.isSignedIn, let name = cloudKit.currentUserName {
                Text(name)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    private var statusIcon: String {
        switch cloudKit.accountStatus {
        case .available:
            return "checkmark.icloud.fill"
        case .noAccount:
            return "person.crop.circle.badge.xmark"
        case .restricted:
            return "lock.icloud.fill"
        case .couldNotDetermine, .temporarilyUnavailable:
            return "exclamationmark.icloud.fill"
        @unknown default:
            return "icloud.slash.fill"
        }
    }

    private var statusColor: Color {
        switch cloudKit.accountStatus {
        case .available:
            return .green
        case .noAccount, .restricted:
            return .orange
        case .couldNotDetermine, .temporarilyUnavailable:
            return .yellow
        @unknown default:
            return .red
        }
    }

    private var statusTitle: String {
        switch cloudKit.accountStatus {
        case .available:
            return "iCloud Connected"
        case .noAccount:
            return "Sign in to iCloud"
        case .restricted:
            return "iCloud Restricted"
        case .couldNotDetermine:
            return "Checking iCloud..."
        case .temporarilyUnavailable:
            return "iCloud Unavailable"
        @unknown default:
            return "iCloud Status Unknown"
        }
    }
}

#Preview {
    CloudSyncStatusView()
        .padding()
}
