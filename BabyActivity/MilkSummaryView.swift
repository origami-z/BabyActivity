//
//  MilkSummaryView.swift
//  BabyActivity
//
//  Created by Claude on 27/01/2026.
//

import SwiftUI
import SwiftData
import Charts

struct MilkSummaryView: View {
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
            let milkActivities = activities.filter { $0.kind == .milk }
            let dailyData = DataController.milkDataByDay(milkActivities)
            let avgPerFeeding = DataController.averageMilkPerFeeding(milkActivities)
            let avgDaily = DataController.averageDailyMilkIntake(milkActivities)
            let avgIntervalMinutes = DataController.averageFeedingIntervalMinutes(milkActivities)

            ScrollView {
                VStack(spacing: 20) {
                    // Stats Cards
                    HStack(spacing: 16) {
                        StatCard(
                            title: "AVG DAILY",
                            value: "\(Int(avgDaily))ml",
                            icon: "chart.bar.fill"
                        )
                        StatCard(
                            title: "AVG/FEEDING",
                            value: "\(Int(avgPerFeeding))ml",
                            icon: Activity.milkImage
                        )
                    }

                    HStack(spacing: 16) {
                        StatCard(
                            title: "FEEDINGS",
                            value: "\(milkActivities.count)",
                            icon: "number"
                        )
                        StatCard(
                            title: "AVG INTERVAL",
                            value: formatIntervalMinutes(avgIntervalMinutes),
                            icon: "clock"
                        )
                    }

                    // Daily Intake Chart
                    VStack(alignment: .leading) {
                        Text("Daily Intake")
                            .font(.headline)
                            .padding(.horizontal)

                        Chart {
                            ForEach(dailyData) { data in
                                BarMark(
                                    x: .value("Date", data.date, unit: .day),
                                    y: .value("Amount", data.totalAmount)
                                )
                                .foregroundStyle(Color.blue.gradient)
                            }

                            // Average line
                            if avgDaily > 0 {
                                RuleMark(y: .value("Average", avgDaily))
                                    .foregroundStyle(.orange)
                                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                                    .annotation(position: .top, alignment: .trailing) {
                                        Text("Avg: \(Int(avgDaily))ml")
                                            .font(.caption)
                                            .foregroundStyle(.orange)
                                    }
                            }
                        }
                        .frame(height: 200)
                        .chartXScale(domain: viewByOption.dateRange)
                        .chartXAxis {
                            AxisMarks(values: .automatic(desiredCount: viewByOption.chartXAxisCount))
                        }
                        .chartYAxis {
                            AxisMarks { value in
                                AxisValueLabel {
                                    if let amount = value.as(Int.self) {
                                        Text("\(amount)ml")
                                    }
                                }
                                AxisGridLine()
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Feeding Frequency Chart
                    VStack(alignment: .leading) {
                        Text("Feedings Per Day")
                            .font(.headline)
                            .padding(.horizontal)

                        Chart {
                            ForEach(dailyData) { data in
                                BarMark(
                                    x: .value("Date", data.date, unit: .day),
                                    y: .value("Count", data.feedingCount)
                                )
                                .foregroundStyle(Color.green.gradient)
                            }
                        }
                        .frame(height: 150)
                        .chartXScale(domain: viewByOption.dateRange)
                        .chartXAxis {
                            AxisMarks(values: .automatic(desiredCount: viewByOption.chartXAxisCount))
                        }
                        .padding(.horizontal)
                    }

                    // Recent Feedings List
                    VStack(alignment: .leading) {
                        Text("Recent Feedings")
                            .font(.headline)
                            .padding(.horizontal)

                        ForEach(milkActivities.suffix(5).reversed()) { activity in
                            HStack {
                                Image(systemName: Activity.milkImage)
                                    .foregroundStyle(.blue)
                                VStack(alignment: .leading) {
                                    Text("\(activity.amount ?? 0)ml")
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
        .navigationTitle("Milk")
    }

    private func formatIntervalMinutes(_ minutes: Double) -> String {
        let hours = Int(minutes) / 60
        let mins = Int(minutes) % 60
        if hours > 0 {
            return "\(hours)h \(mins)m"
        } else {
            return "\(mins)m"
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)
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
        MilkSummaryView()
            .modelContainer(DataController.previewContainer)
    }
}
