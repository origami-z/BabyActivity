//
//  DiaperSummaryView.swift
//  BabyActivity
//
//  Created by Claude on 27/01/2026.
//

import SwiftUI
import SwiftData
import Charts

struct DiaperSummaryView: View {
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
            let diaperActivities = activities.filter { $0.kind == .wetDiaper || $0.kind == .dirtyDiaper }
            let dailyData = DataController.diaperDataByDay(diaperActivities)
            let hourlyData = DataController.diaperDataByHour(diaperActivities)
            let avgPerDay = DataController.averageDiapersPerDay(diaperActivities)

            let wetCount = diaperActivities.filter { $0.kind == .wetDiaper }.count
            let dirtyCount = diaperActivities.filter { $0.kind == .dirtyDiaper }.count

            ScrollView {
                VStack(spacing: 20) {
                    // Stats Cards
                    HStack(spacing: 16) {
                        StatCard(
                            title: "TOTAL",
                            value: "\(diaperActivities.count)",
                            icon: "number"
                        )
                        StatCard(
                            title: "AVG/DAY",
                            value: String(format: "%.1f", avgPerDay),
                            icon: "chart.bar.fill"
                        )
                    }

                    HStack(spacing: 16) {
                        DiaperStatCard(
                            title: "WET",
                            value: "\(wetCount)",
                            icon: Activity.wetDiaperImage,
                            color: .cyan
                        )
                        DiaperStatCard(
                            title: "DIRTY",
                            value: "\(dirtyCount)",
                            icon: Activity.dirtyDiaperImage,
                            color: .brown
                        )
                    }

                    // Daily Count Stacked Bar Chart
                    VStack(alignment: .leading) {
                        Text("Daily Diapers")
                            .font(.headline)
                            .padding(.horizontal)

                        Chart {
                            ForEach(dailyData) { data in
                                BarMark(
                                    x: .value("Date", data.date, unit: .day),
                                    y: .value("Count", data.wetCount)
                                )
                                .foregroundStyle(by: .value("Type", "Wet"))

                                BarMark(
                                    x: .value("Date", data.date, unit: .day),
                                    y: .value("Count", data.dirtyCount)
                                )
                                .foregroundStyle(by: .value("Type", "Dirty"))
                            }
                        }
                        .chartForegroundStyleScale([
                            "Wet": Color.cyan,
                            "Dirty": Color.brown
                        ])
                        .frame(height: 200)
                        .chartXScale(domain: viewByOption.dateRange)
                        .chartXAxis {
                            AxisMarks(values: .automatic(desiredCount: viewByOption.chartXAxisCount))
                        }
                        .chartLegend(position: .bottom)
                        .padding(.horizontal)
                    }

                    // Time of Day Distribution
                    VStack(alignment: .leading) {
                        Text("Time of Day Pattern")
                            .font(.headline)
                            .padding(.horizontal)

                        Chart {
                            ForEach(hourlyData) { data in
                                let total = data.wetCount + data.dirtyCount
                                if total > 0 {
                                    BarMark(
                                        x: .value("Hour", data.hour),
                                        y: .value("Count", data.wetCount)
                                    )
                                    .foregroundStyle(by: .value("Type", "Wet"))

                                    BarMark(
                                        x: .value("Hour", data.hour),
                                        y: .value("Count", data.dirtyCount)
                                    )
                                    .foregroundStyle(by: .value("Type", "Dirty"))
                                }
                            }
                        }
                        .chartForegroundStyleScale([
                            "Wet": Color.cyan,
                            "Dirty": Color.brown
                        ])
                        .frame(height: 150)
                        .chartXAxis {
                            AxisMarks(values: .stride(by: 4)) { value in
                                if let hour = value.as(Int.self) {
                                    AxisValueLabel {
                                        Text(formatHour(hour))
                                    }
                                }
                                AxisGridLine()
                            }
                        }
                        .chartXScale(domain: 0...23)
                        .chartLegend(.hidden)
                        .padding(.horizontal)

                        Text("Shows when diapers are most commonly changed")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)
                    }

                    // Recent Changes List
                    VStack(alignment: .leading) {
                        Text("Recent Changes")
                            .font(.headline)
                            .padding(.horizontal)

                        ForEach(diaperActivities.suffix(5).reversed()) { activity in
                            HStack {
                                Image(systemName: activity.image)
                                    .foregroundStyle(activity.kind == .wetDiaper ? .cyan : .brown)
                                VStack(alignment: .leading) {
                                    Text(activity.kind == .wetDiaper ? "Wet Diaper" : "Dirty Diaper")
                                        .font(.subheadline)
                                    Text(activity.timestamp, style: .relative)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
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
        .navigationTitle("Diapers")
    }

    private func formatHour(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "ha"
        let date = Calendar.current.date(from: DateComponents(hour: hour))!
        return formatter.string(from: date).lowercased()
    }
}

struct DiaperStatCard: View {
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
        DiaperSummaryView()
            .modelContainer(DataController.previewContainer)
    }
}
