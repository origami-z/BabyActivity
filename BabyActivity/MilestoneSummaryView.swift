//
//  MilestoneSummaryView.swift
//  BabyActivity
//
//  Milestone tracking with achievements and photo support
//

import SwiftUI
import SwiftData
import PhotosUI

struct MilestoneSummaryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Milestone.timestamp, order: .reverse) private var milestones: [Milestone]
    @State private var showingAddMilestone = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Stats
                HStack(spacing: 16) {
                    MilestoneStatCard(
                        title: "ACHIEVED",
                        value: "\(milestones.count)",
                        icon: "star.fill",
                        color: .yellow
                    )
                    MilestoneStatCard(
                        title: "THIS MONTH",
                        value: "\(milestonesThisMonth)",
                        icon: "calendar",
                        color: .blue
                    )
                }
                .padding(.horizontal)

                // Milestones Timeline
                if milestones.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "star.circle")
                            .font(.system(size: 60))
                            .foregroundStyle(.secondary)
                        Text("No milestones recorded yet")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        Text("Start tracking your baby's achievements!")
                            .font(.subheadline)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 60)
                } else {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Milestones")
                            .font(.headline)
                            .padding(.horizontal)

                        ForEach(milestones) { milestone in
                            MilestoneCard(milestone: milestone)
                        }
                    }
                }

                // Add Button
                Button {
                    showingAddMilestone = true
                } label: {
                    Label("Add Milestone", systemImage: "plus.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.yellow)
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("Milestones")
        .sheet(isPresented: $showingAddMilestone) {
            AddMilestoneView()
        }
    }

    private var milestonesThisMonth: Int {
        let calendar = Calendar.current
        let now = Date()
        return milestones.filter { calendar.isDate($0.timestamp, equalTo: now, toGranularity: .month) }.count
    }
}

struct MilestoneCard: View {
    let milestone: Milestone

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                Image(systemName: milestone.milestoneType.icon)
                    .font(.title2)
                    .foregroundStyle(.yellow)
                    .frame(width: 40, height: 40)
                    .background(Color.yellow.opacity(0.2))
                    .cornerRadius(8)

                VStack(alignment: .leading, spacing: 4) {
                    Text(milestone.title)
                        .font(.headline)
                    Text(milestone.timestamp, style: .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            if let notes = milestone.notes, !notes.isEmpty {
                Text(notes)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if let photoData = milestone.photoData,
               let uiImage = UIImage(data: photoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 150)
                    .clipped()
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct MilestoneStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct AddMilestoneView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var selectedType: MilestoneType = .firstSmile
    @State private var customTitle: String = ""
    @State private var notes: String = ""
    @State private var date: Date = Date()
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var photoData: Data?

    var body: some View {
        NavigationStack {
            Form {
                Picker("Milestone", selection: $selectedType) {
                    ForEach(MilestoneType.allCases, id: \.rawValue) { type in
                        Label(type.description, systemImage: type.icon).tag(type)
                    }
                }

                if selectedType == .other {
                    TextField("Custom Title", text: $customTitle)
                }

                DatePicker("Date", selection: $date, displayedComponents: .date)

                TextField("Notes (optional)", text: $notes, axis: .vertical)
                    .lineLimit(3...6)

                Section("Photo") {
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        if let photoData = photoData,
                           let uiImage = UIImage(data: photoData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 150)
                                .clipped()
                                .cornerRadius(8)
                        } else {
                            Label("Add Photo", systemImage: "photo.badge.plus")
                        }
                    }
                    .onChange(of: selectedPhoto) { oldValue, newValue in
                        Task {
                            if let data = try? await newValue?.loadTransferable(type: Data.self) {
                                photoData = data
                            }
                        }
                    }

                    if photoData != nil {
                        Button("Remove Photo", role: .destructive) {
                            photoData = nil
                            selectedPhoto = nil
                        }
                    }
                }
            }
            .navigationTitle("Add Milestone")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let milestone = Milestone(
                            milestoneType: selectedType,
                            timestamp: date,
                            customTitle: selectedType == .other ? customTitle : nil,
                            notes: notes.isEmpty ? nil : notes,
                            photoData: photoData
                        )
                        modelContext.insert(milestone)
                        dismiss()
                    }
                    .disabled(selectedType == .other && customTitle.isEmpty)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        MilestoneSummaryView()
            .modelContainer(DataController.previewContainer)
    }
}
