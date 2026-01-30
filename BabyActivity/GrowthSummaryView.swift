//
//  GrowthSummaryView.swift
//  BabyActivity
//
//  Growth measurements tracking with charts
//

import SwiftUI
import SwiftData
import Charts

struct GrowthSummaryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \GrowthMeasurement.timestamp, order: .reverse) private var measurements: [GrowthMeasurement]
    @State private var selectedType: GrowthMeasurementType = .weight
    @State private var showingAddMeasurement = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Measurement Type Picker
                Picker("Measurement Type", selection: $selectedType) {
                    ForEach(GrowthMeasurementType.allCases, id: \.rawValue) { type in
                        Text(type.description).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                // Latest Measurement Card
                let filteredMeasurements = measurements.filter { $0.measurementType == selectedType }
                if let latest = filteredMeasurements.first {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Latest \(selectedType.description)")
                            .font(.headline)
                            .padding(.horizontal)

                        HStack {
                            Image(systemName: selectedType.icon)
                                .font(.largeTitle)
                                .foregroundStyle(colorForType(selectedType))

                            VStack(alignment: .leading) {
                                Text(String(format: "%.1f %@", latest.value, selectedType.unit))
                                    .font(.title)
                                    .fontWeight(.bold)
                                Text(latest.timestamp, style: .date)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            if filteredMeasurements.count >= 2 {
                                let previous = filteredMeasurements[1]
                                let change = latest.value - previous.value
                                VStack(alignment: .trailing) {
                                    HStack(spacing: 4) {
                                        Image(systemName: change >= 0 ? "arrow.up" : "arrow.down")
                                        Text(String(format: "%.1f", abs(change)))
                                    }
                                    .font(.subheadline)
                                    .foregroundStyle(change >= 0 ? .green : .red)
                                    Text("since last")
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                }

                // Growth Chart
                if filteredMeasurements.count >= 2 {
                    VStack(alignment: .leading) {
                        Text("\(selectedType.description) Over Time")
                            .font(.headline)
                            .padding(.horizontal)

                        Chart {
                            ForEach(filteredMeasurements.reversed()) { measurement in
                                LineMark(
                                    x: .value("Date", measurement.timestamp),
                                    y: .value(selectedType.description, measurement.value)
                                )
                                .foregroundStyle(colorForType(selectedType))
                                .interpolationMethod(.catmullRom)

                                PointMark(
                                    x: .value("Date", measurement.timestamp),
                                    y: .value(selectedType.description, measurement.value)
                                )
                                .foregroundStyle(colorForType(selectedType))
                            }
                        }
                        .frame(height: 200)
                        .chartYAxisLabel(selectedType.unit)
                        .padding(.horizontal)
                    }
                }

                // Measurement History
                VStack(alignment: .leading) {
                    Text("History")
                        .font(.headline)
                        .padding(.horizontal)

                    if filteredMeasurements.isEmpty {
                        Text("No \(selectedType.description.lowercased()) measurements yet")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding()
                    } else {
                        ForEach(filteredMeasurements.prefix(10)) { measurement in
                            HStack {
                                Image(systemName: measurement.measurementType.icon)
                                    .foregroundStyle(colorForType(measurement.measurementType))
                                VStack(alignment: .leading) {
                                    Text(String(format: "%.1f %@", measurement.value, measurement.measurementType.unit))
                                        .font(.subheadline)
                                    Text(measurement.timestamp, style: .date)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                if let notes = measurement.notes, !notes.isEmpty {
                                    Image(systemName: "note.text")
                                        .foregroundStyle(.secondary)
                                        .font(.caption)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 4)
                        }
                    }
                }

                // Add Measurement Button
                Button {
                    showingAddMeasurement = true
                } label: {
                    Label("Add Measurement", systemImage: "plus.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(colorForType(selectedType))
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("Growth")
        .sheet(isPresented: $showingAddMeasurement) {
            AddGrowthMeasurementView(selectedType: selectedType)
        }
    }

    private func colorForType(_ type: GrowthMeasurementType) -> Color {
        switch type {
        case .weight: return .purple
        case .height: return .blue
        case .headCircumference: return .teal
        }
    }
}

struct AddGrowthMeasurementView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State var selectedType: GrowthMeasurementType
    @State private var value: Double = 0
    @State private var date: Date = Date()
    @State private var notes: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Picker("Type", selection: $selectedType) {
                    ForEach(GrowthMeasurementType.allCases, id: \.rawValue) { type in
                        Text(type.description).tag(type)
                    }
                }

                HStack {
                    Text("Value")
                    Spacer()
                    TextField("Value", value: $value, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 100)
                    Text(selectedType.unit)
                        .foregroundStyle(.secondary)
                }

                DatePicker("Date", selection: $date, displayedComponents: .date)

                TextField("Notes (optional)", text: $notes)
            }
            .navigationTitle("Add Measurement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let measurement = GrowthMeasurement(
                            measurementType: selectedType,
                            timestamp: date,
                            value: value,
                            notes: notes.isEmpty ? nil : notes
                        )
                        modelContext.insert(measurement)
                        dismiss()
                    }
                    .disabled(value <= 0)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        GrowthSummaryView()
            .modelContainer(DataController.previewContainer)
    }
}
