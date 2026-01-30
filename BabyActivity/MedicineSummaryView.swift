//
//  MedicineSummaryView.swift
//  BabyActivity
//
//  Medicine tracking with dosage history and schedule
//

import SwiftUI
import SwiftData
import Charts

struct MedicineSummaryView: View {
    @Environment(\.modelContext) private var modelContext
    @State var viewByOption: ViewByOption = .week

    var dateRangeDescriptor: FetchDescriptor<Activity> {
        let dateRange = viewByOption.dateRange
        let startDate = dateRange.lowerBound
        let endDate = dateRange.upperBound

        let predicate = #Predicate<Activity> { activity in
            return activity.timestamp >= startDate && activity.timestamp <= endDate
        }
        return FetchDescriptor<Activity>(predicate: predicate, sortBy: [SortDescriptor(\Activity.timestamp)])
    }

    var body: some View {
        Picker("View by", selection: $viewByOption) {
            ForEach(ViewByOption.allCases, id: \.rawValue) { option in
                Text(option.rawValue.first?.uppercased() ?? "").tag(option)
            }
        }
        .pickerStyle(.segmented)

        DynamicQuery(dateRangeDescriptor) { activities in
            let medicineActivities = activities.filter { $0.kind == .medicine }
            let uniqueMedicines = DataController.uniqueMedicines(medicineActivities)
            let dailyData = DataController.medicineDataByDay(medicineActivities)

            ScrollView {
                VStack(spacing: 20) {
                    // Stats Cards
                    HStack(spacing: 16) {
                        MedicineStatCard(
                            title: "MEDICINES",
                            value: "\(uniqueMedicines.count)",
                            icon: "pills.fill",
                            color: .red
                        )
                        MedicineStatCard(
                            title: "DOSES",
                            value: "\(medicineActivities.count)",
                            icon: "number",
                            color: .blue
                        )
                    }

                    // Daily Doses Chart
                    VStack(alignment: .leading) {
                        Text("Daily Doses")
                            .font(.headline)
                            .padding(.horizontal)

                        Chart {
                            ForEach(dailyData) { data in
                                BarMark(
                                    x: .value("Date", data.date, unit: .day),
                                    y: .value("Doses", data.doseCount)
                                )
                                .foregroundStyle(Color.red.gradient)
                            }
                        }
                        .frame(height: 150)
                        .chartXScale(domain: viewByOption.dateRange)
                        .chartXAxis {
                            AxisMarks(values: .automatic(desiredCount: viewByOption.chartXAxisCount))
                        }
                        .padding(.horizontal)
                    }

                    // Medicines List
                    if !uniqueMedicines.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Active Medicines")
                                .font(.headline)
                                .padding(.horizontal)

                            ForEach(uniqueMedicines, id: \.self) { medicine in
                                let medicineActivitiesList = medicineActivities.filter { $0.medicineName == medicine }
                                let lastDose = medicineActivitiesList.last
                                let dosageInfo = lastDose?.dosage ?? ""

                                HStack {
                                    Image(systemName: "cross.case.fill")
                                        .foregroundStyle(.red)
                                        .font(.title3)

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(medicine)
                                            .font(.headline)
                                        if !dosageInfo.isEmpty {
                                            Text("Dosage: \(dosageInfo)")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        if let last = lastDose {
                                            Text("Last: \(last.timestamp, style: .relative)")
                                                .font(.caption2)
                                                .foregroundStyle(.tertiary)
                                        }
                                    }

                                    Spacer()

                                    Text("\(medicineActivitiesList.count) doses")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                                .padding(.horizontal)
                            }
                        }
                    }

                    // Recent Doses
                    VStack(alignment: .leading) {
                        Text("Recent Doses")
                            .font(.headline)
                            .padding(.horizontal)

                        ForEach(medicineActivities.suffix(10).reversed()) { activity in
                            HStack {
                                Image(systemName: Activity.medicineImage)
                                    .foregroundStyle(.red)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(activity.medicineName ?? "Unknown")
                                        .font(.subheadline)
                                    HStack(spacing: 8) {
                                        if let dosage = activity.dosage, !dosage.isEmpty {
                                            Text(dosage)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        Text(activity.timestamp, style: .relative)
                                            .font(.caption)
                                            .foregroundStyle(.tertiary)
                                    }
                                }
                                Spacer()
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 4)
                        }
                    }
                }
                .padding(.vertical)
            }
        }
        .navigationTitle("Medicine")
    }
}

struct MedicineStatCard: View {
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

#Preview {
    NavigationStack {
        MedicineSummaryView()
            .modelContainer(DataController.previewContainer)
    }
}
