//
//  FamilySharingView.swift
//  BabyActivity
//
//  View for managing family sharing and permissions
//

import SwiftUI
import SwiftData
import CloudKit

struct FamilySharingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var cloudKit = CloudKitService.shared

    let baby: Baby

    @State private var showingAddMember = false
    @State private var showingEditPermission = false
    @State private var selectedMember: FamilyMember?
    @State private var newMemberEmail = ""
    @State private var newMemberPermission: PermissionLevel = .caregiver
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingShareSheet = false

    var body: some View {
        NavigationStack {
            List {
                // iCloud Status Section
                Section {
                    CloudSyncStatusView()
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }

                // Owner Section
                Section("Profile Owner") {
                    HStack {
                        Image(systemName: PermissionLevel.admin.icon)
                            .foregroundColor(.yellow)
                            .frame(width: 30)

                        VStack(alignment: .leading) {
                            Text(cloudKit.currentUserName ?? "You")
                                .font(.body)
                            Text("Owner")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Text(PermissionLevel.admin.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.yellow.opacity(0.2))
                            .cornerRadius(6)
                    }
                }

                // Shared With Section
                Section {
                    if baby.sharedWith.isEmpty {
                        ContentUnavailableView(
                            "No Family Members",
                            systemImage: "person.2.slash",
                            description: Text("Tap + to invite family members to track \(baby.name)'s activities together.")
                        )
                        .listRowBackground(Color.clear)
                    } else {
                        ForEach(baby.sharedWith) { member in
                            FamilyMemberRow(member: member) {
                                selectedMember = member
                                showingEditPermission = true
                            }
                        }
                        .onDelete(perform: removeMember)
                    }
                } header: {
                    HStack {
                        Text("Shared With")
                        Spacer()
                        Button {
                            showingAddMember = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.accentColor)
                        }
                    }
                } footer: {
                    Text("Family members can help track \(baby.name)'s activities based on their permission level.")
                }

                // Permissions Guide Section
                Section("Permission Levels") {
                    ForEach(PermissionLevel.allCases, id: \.self) { level in
                        HStack {
                            Image(systemName: level.icon)
                                .foregroundColor(permissionColor(level))
                                .frame(width: 30)

                            VStack(alignment: .leading) {
                                Text(level.description)
                                    .font(.body)
                                Text(level.detailedDescription)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }

                // Share via System Sheet Section
                Section {
                    Button {
                        showingShareSheet = true
                    } label: {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share via iCloud")
                        }
                    }
                    .disabled(!cloudKit.isSignedIn)
                } footer: {
                    Text("Use iCloud sharing to invite family members directly.")
                }
            }
            .navigationTitle("Family Sharing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingAddMember) {
                AddFamilyMemberView(baby: baby)
            }
            .sheet(isPresented: $showingEditPermission) {
                if let member = selectedMember {
                    EditPermissionView(baby: baby, member: member)
                }
            }
            .alert("Error", isPresented: .init(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    private func removeMember(at offsets: IndexSet) {
        for index in offsets {
            let member = baby.sharedWith[index]
            baby.sharedWith.remove(at: index)
            modelContext.delete(member)
        }
        baby.lastModified = Date()
    }

    private func permissionColor(_ level: PermissionLevel) -> Color {
        switch level {
        case .admin: return .yellow
        case .caregiver: return .blue
        case .viewer: return .gray
        }
    }
}

// MARK: - Family Member Row

struct FamilyMemberRow: View {
    let member: FamilyMember
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: member.permission.icon)
                    .foregroundColor(permissionColor)
                    .frame(width: 30)

                VStack(alignment: .leading) {
                    Text(member.displayName)
                        .font(.body)
                        .foregroundColor(.primary)

                    Text("Added \(member.addedDate.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text(member.permission.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(permissionColor.opacity(0.2))
                    .cornerRadius(6)

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var permissionColor: Color {
        switch member.permission {
        case .admin: return .yellow
        case .caregiver: return .blue
        case .viewer: return .gray
        }
    }
}

// MARK: - Add Family Member View

struct AddFamilyMemberView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var cloudKit = CloudKitService.shared

    let baby: Baby

    @State private var displayName = ""
    @State private var email = ""
    @State private var permission: PermissionLevel = .caregiver
    @State private var isSearching = false
    @State private var foundUserID: String?
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Member Details") {
                    TextField("Name", text: $displayName)
                        .textContentType(.name)

                    TextField("Email Address", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }

                Section("Permission Level") {
                    Picker("Permission", selection: $permission) {
                        ForEach([PermissionLevel.caregiver, PermissionLevel.viewer], id: \.self) { level in
                            HStack {
                                Image(systemName: level.icon)
                                Text(level.description)
                            }
                            .tag(level)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }

                Section {
                    Text(permission.detailedDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Add Family Member")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add") {
                        addMember()
                    }
                    .disabled(displayName.isEmpty)
                }
            }
            .alert("Error", isPresented: .init(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    private func addMember() {
        // Use email as the CloudKit user ID placeholder
        // In production, this would look up the actual user via CloudKit
        let userID = email.isEmpty ? UUID().uuidString : email

        let member = baby.addFamilyMember(
            cloudKitUserID: userID,
            displayName: displayName,
            permission: permission
        )

        dismiss()
    }
}

// MARK: - Edit Permission View

struct EditPermissionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let baby: Baby
    let member: FamilyMember

    @State private var permission: PermissionLevel
    @State private var showingRemoveConfirmation = false

    init(baby: Baby, member: FamilyMember) {
        self.baby = baby
        self.member = member
        self._permission = State(initialValue: member.permission)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Member") {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.title)
                            .foregroundColor(.secondary)

                        VStack(alignment: .leading) {
                            Text(member.displayName)
                                .font(.headline)
                            Text("Added \(member.addedDate.formatted(date: .long, time: .omitted))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Section("Permission Level") {
                    Picker("Permission", selection: $permission) {
                        ForEach(PermissionLevel.allCases, id: \.self) { level in
                            HStack {
                                Image(systemName: level.icon)
                                Text(level.description)
                            }
                            .tag(level)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }

                Section {
                    Text(permission.detailedDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Section {
                    Button(role: .destructive) {
                        showingRemoveConfirmation = true
                    } label: {
                        HStack {
                            Image(systemName: "person.badge.minus")
                            Text("Remove from \(baby.name)'s Profile")
                        }
                    }
                }
            }
            .navigationTitle("Edit Permission")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(permission == member.permission)
                }
            }
            .confirmationDialog(
                "Remove \(member.displayName)?",
                isPresented: $showingRemoveConfirmation,
                titleVisibility: .visible
            ) {
                Button("Remove", role: .destructive) {
                    removeMember()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("They will no longer be able to view or edit \(baby.name)'s activities.")
            }
        }
    }

    private func saveChanges() {
        member.permission = permission
        baby.lastModified = Date()
        dismiss()
    }

    private func removeMember() {
        baby.removeFamilyMember(cloudKitUserID: member.cloudKitUserID)
        modelContext.delete(member)
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Baby.self, FamilyMember.self, configurations: config)

    let baby = Baby(name: "Emma", birthDate: Calendar.current.date(byAdding: .month, value: -6, to: Date())!)
    container.mainContext.insert(baby)

    return FamilySharingView(baby: baby)
        .modelContainer(container)
}
