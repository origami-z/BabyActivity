//
//  TummyTimeSummaryView.swift
//  BabyActivity
//
//  Tummy time analytics with duration tracking and daily goals
//

import SwiftUI
import SwiftData
import Charts

struct TummyTimeSummaryView: View {
    @Environment(\.modelContext) private var modelContext
    @State var viewByOption: ViewByOption = .week

    var dateRangeDescriptor: FetchDescriptor<Activity> {
        let dateRange = viewByOption.dateRange
        let startDate = dateRange.lowerBound
        let endDate = dateRange.upperBound

        let predicate = #Predicate<Activity> { activity in
            return activity.endTimestamp.flatMap { $0 >= startDate } == true && activity.timestamp <= endDate
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
            let tummyTimeActivities = activities.filter { $0.kind == .tummyTime }
            let dailyData = DataController.tummyTimeDataByDay(tummyTimeActivities)
            let averagePerDay = DataController.averageTummyTimePerDay(tummyTimeActivities)
            let totalSessions = tummyTimeActivities.count

            ScrollView {
                VStack(spacing: 20) {
                    // Stats Cards
                    HStack(spacing: 16) {
                        TummyTimeStatCard(
                            title: "AVG/DAY",
                            value: formatMinutes(averagePerDay),
                            icon: "chart.bar.fill",
                            color: .green
                        )
                        TummyTimeStatCard(
                            title: "SESSIONS",
                            value: "\(totalSessions)",
                            icon: "number",
                            color: .blue
                        )
                    }

                    // Daily Goal Progress
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Daily Goal Progress")
                            .font(.headline)
                            .padding(.horizontal)

                        let todayData = dailyData.last
                        let todayMinutes = todayData?.totalMinutes ?? 0
                        let goalMinutes: Double = 30 // Recommended 30 minutes per day
                        let progress = min(todayMinutes / goalMinutes, 1.0)

                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Today: \(formatMinutes(todayMinutes))")
                                    .font(.subheadline)
                                Spacer()
                                Text("Goal: \(Int(goalMinutes))m")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            ProgressView(value: progress)
                                .tint(progress >= 1.0 ? .green : .orange)

                            if progress >= 1.0 {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                    Text("Goal achieved!")
                                        .font(.caption)
                                        .foregroundStyle(.green)
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }

                    // Daily Duration Chart
                    VStack(alignment: .leading) {
                        Text("Daily Tummy Time")
                            .font(.headline)
                            .padding(.horizontal)

                        Chart {
                            ForEach(dailyData) { data in
                                BarMark(
                                    x: .value("Date", data.date, unit: .day),
                                    y: .value("Minutes", data.totalMinutes)
                                )
                                .foregroundStyle(Color.green.gradient)
                            }

                            // Goal line
                            RuleMark(y: .value("Goal", 30))
                                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
                                .foregroundStyle(.orange)
                                .annotation(position: .top, alignment: .trailing) {
                                    Text("30m goal")
                                        .font(.caption2)
                                        .foregroundStyle(.orange)
                                }
                        }
                        .frame(height: 200)
                        .chartXScale(domain: viewByOption.dateRange)
                        .chartXAxis {
                            AxisMarks(values: .automatic(desiredCount: viewByOption.chartXAxisCount))
                        }
                        .chartYAxisLabel("Minutes")
                        .padding(.horizontal)
                    }

                    // Session Count by Day
                    VStack(alignment: .leading) {
                        Text("Sessions per Day")
                            .font(.headline)
                            .padding(.horizontal)

                        Chart {
                            ForEach(dailyData) { data in
                                BarMark(
                                    x: .value("Date", data.date, unit: .day),
                                    y: .value("Sessions", data.sessionCount)
                                )
                                .foregroundStyle(Color.blue.gradient)
                            }
                        }
                        .frame(height: 150)
                        .chartXScale(domain: viewByOption.dateRange)
                        .chartXAxis {
                            AxisMarks(values: .automatic(desiredCount: viewByOption.chartXAxisCount))
                        }
                        .padding(.horizontal)
                    }

                    // Recent Sessions
                    VStack(alignment: .leading) {
                        Text("Recent Sessions")
                            .font(.headline)
                            .padding(.horizontal)

                        ForEach(tummyTimeActivities.suffix(5).reversed()) { activity in
                            if let end = activity.endTimestamp {
                                let duration = end.timeIntervalSince(activity.timestamp) / 60
                                HStack {
                                    Image(systemName: Activity.tummyTimeImage)
                                        .foregroundStyle(.green)
                                    VStack(alignment: .leading) {
                                        Text(formatMinutes(duration))
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
                }
                .padding(.vertical)
            }
        }
        .navigationTitle("Tummy Time")
    }

    private func formatMinutes(_ minutes: Double) -> String {
        let hours = Int(minutes) / 60
        let mins = Int(minutes) % 60
        if hours > 0 {
            return "\(hours)h \(mins)m"
        } else {
            return "\(mins)m"
        }
    }
}

struct TummyTimeStatCard: View {
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
        TummyTimeSummaryView()
            .modelContainer(DataController.previewContainer)
    }
}
