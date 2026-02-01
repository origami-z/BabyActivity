//
//  BabyProfileView.swift
//  BabyActivity
//
//  View for managing baby profiles
//

import SwiftUI
import SwiftData
import PhotosUI

struct BabyProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var babies: [Baby]
    @ObservedObject private var cloudKit = CloudKitService.shared

    @State private var showingAddBaby = false
    @State private var selectedBaby: Baby?
    @State private var showingEditBaby = false
    @State private var showingFamilySharing = false

    var body: some View {
        NavigationStack {
            List {
                // iCloud Status
                Section {
                    CloudSyncStatusView()
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }

                // Baby Profiles Section
                Section {
                    if babies.isEmpty {
                        ContentUnavailableView(
                            "No Profiles",
                            systemImage: "person.crop.circle.badge.plus",
                            description: Text("Create a profile for your baby to start tracking activities.")
                        )
                        .listRowBackground(Color.clear)
                    } else {
                        ForEach(babies) { baby in
                            BabyProfileRow(baby: baby) {
                                selectedBaby = baby
                                showingEditBaby = true
                            } onShareTapped: {
                                selectedBaby = baby
                                showingFamilySharing = true
                            }
                        }
                        .onDelete(perform: deleteBabies)
                    }
                } header: {
                    HStack {
                        Text("Baby Profiles")
                        Spacer()
                        Button {
                            showingAddBaby = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.accentColor)
                        }
                    }
                } footer: {
                    Text("Your baby profiles sync automatically across all your devices via iCloud.")
                }
            }
            .navigationTitle("Profiles")
            .sheet(isPresented: $showingAddBaby) {
                EditBabyView(baby: nil)
            }
            .sheet(isPresented: $showingEditBaby) {
                if let baby = selectedBaby {
                    EditBabyView(baby: baby)
                }
            }
            .sheet(isPresented: $showingFamilySharing) {
                if let baby = selectedBaby {
                    FamilySharingView(baby: baby)
                }
            }
        }
    }

    private func deleteBabies(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(babies[index])
        }
    }
}

// MARK: - Baby Profile Row

struct BabyProfileRow: View {
    let baby: Baby
    let onEditTapped: () -> Void
    let onShareTapped: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Profile Photo
            if let photoData = baby.photoData, let uiImage = UIImage(data: photoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
            } else {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.secondary)
            }

            // Name and Age
            VStack(alignment: .leading, spacing: 4) {
                Text(baby.name)
                    .font(.headline)

                Text(baby.ageDisplay)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                // Sharing indicator
                if !baby.sharedWith.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "person.2.fill")
                            .font(.caption2)
                        Text("Shared with \(baby.sharedWith.count)")
                            .font(.caption)
                    }
                    .foregroundColor(.blue)
                }
            }

            Spacer()

            // Action Buttons
            HStack(spacing: 12) {
                Button {
                    onShareTapped()
                } label: {
                    Image(systemName: "person.badge.plus")
                        .font(.title3)
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)

                Button {
                    onEditTapped()
                } label: {
                    Image(systemName: "pencil.circle.fill")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Edit Baby View

struct EditBabyView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var cloudKit = CloudKitService.shared

    let baby: Baby?

    @State private var name: String
    @State private var birthDate: Date
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var photoData: Data?
    @State private var showingValidationError = false

    var isNewBaby: Bool { baby == nil }

    init(baby: Baby?) {
        self.baby = baby
        self._name = State(initialValue: baby?.name ?? "")
        self._birthDate = State(initialValue: baby?.birthDate ?? Date())
        self._photoData = State(initialValue: baby?.photoData)
    }

    var body: some View {
        NavigationStack {
            Form {
                // Photo Section
                Section {
                    HStack {
                        Spacer()
                        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                            if let data = photoData, let uiImage = UIImage(data: data) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 120, height: 120)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                                    )
                            } else {
                                ZStack {
                                    Circle()
                                        .fill(Color.secondary.opacity(0.2))
                                        .frame(width: 120, height: 120)

                                    VStack(spacing: 8) {
                                        Image(systemName: "camera.fill")
                                            .font(.title)
                                        Text("Add Photo")
                                            .font(.caption)
                                    }
                                    .foregroundColor(.secondary)
                                }
                            }
                        }
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }
                .onChange(of: selectedPhotoItem) { _, newValue in
                    Task {
                        if let data = try? await newValue?.loadTransferable(type: Data.self) {
                            photoData = data
                        }
                    }
                }

                // Details Section
                Section("Details") {
                    TextField("Name", text: $name)
                        .textContentType(.name)

                    DatePicker("Birth Date", selection: $birthDate, displayedComponents: .date)
                }

                // Age Display Section
                if !isNewBaby, let baby = baby {
                    Section("Age") {
                        HStack {
                            Image(systemName: "birthday.cake.fill")
                                .foregroundColor(.pink)
                            Text(baby.ageDisplay)
                        }
                    }
                }

                // Remove Photo Section
                if photoData != nil {
                    Section {
                        Button(role: .destructive) {
                            photoData = nil
                            selectedPhotoItem = nil
                        } label: {
                            HStack {
                                Image(systemName: "trash")
                                Text("Remove Photo")
                            }
                        }
                    }
                }
            }
            .navigationTitle(isNewBaby ? "Add Baby" : "Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button(isNewBaby ? "Add" : "Save") {
                        save()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .alert("Invalid Name", isPresented: $showingValidationError) {
                Button("OK") {}
            } message: {
                Text("Please enter a name for the baby.")
            }
        }
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            showingValidationError = true
            return
        }

        if let baby = baby {
            // Update existing baby
            baby.name = trimmedName
            baby.birthDate = birthDate
            baby.photoData = photoData
            baby.lastModified = Date()
        } else {
            // Create new baby
            let newBaby = Baby(
                name: trimmedName,
                birthDate: birthDate,
                photoData: photoData,
                ownerCloudKitID: cloudKit.currentUserID
            )
            modelContext.insert(newBaby)
        }

        dismiss()
    }
}

// MARK: - Preview

#Preview("Profile List") {
    BabyProfileView()
        .modelContainer(DataController.previewContainer)
}

#Preview("Add Baby") {
    EditBabyView(baby: nil)
}
