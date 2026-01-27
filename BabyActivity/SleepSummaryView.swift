//
//  SleepSummaryView.swift
//  BabyActivity
//
//  Created by Zhihao Cui on 20/12/2024.
//

import SwiftUI
import SwiftData
import Charts

enum ViewByOption: String, CaseIterable {
    case day
    case week
    case month
}

extension ViewByOption {
    var dateRange: ClosedRange<Date> {
        switch self {
        case .day:
            return Date().addingTimeInterval(-24 * 60 * 60)...Date()
        case .week:
            return Date().addingTimeInterval(-7 * 24 * 60 * 60)...Date()
        case .month:
            return Date().addingTimeInterval(-30 * 24 * 60 * 60)...Date()
        }
    }

    var chartXAxisCount: Int {
        switch self {
        case .day:
            return 1
        case .week:
            return 7
        case .month:
            return 5
        }
    }
}

// https://stackoverflow.com/a/78116918
struct DynamicQuery<Element: PersistentModel, Content: View>: View {
    let descriptor: FetchDescriptor<Element>
    let content: ([Element]) -> Content
    
    @Query var items: [Element]
    
    init(_ descriptor: FetchDescriptor<Element>, @ViewBuilder content: @escaping ([Element]) -> Content) {
        self.descriptor = descriptor
        self.content = content
        _items = Query(descriptor)
    }
    
    var body: some View {
        content(items)
    }
}

struct SleepSummaryView: View {
    @Environment(\.modelContext) private var modelContext
    @State var viewByOption: ViewByOption = .week

    var dateRangeDescriptor: FetchDescriptor<Activity> {
        let dateRange = viewByOption.dateRange
        let startDate = dateRange.lowerBound
        let endDate = dateRange.upperBound

        let predicate = #Predicate<Activity> { activity in
            // data is enum, can't be used in query, only filter by time (start time)
            // can't query .kind enum here, or it will crash at runtime
            // has to use flatMap here, force unwrap doesn't work in predicate..?
            return activity.endTimestamp.flatMap{ $0 >= startDate} == true && activity.timestamp <= endDate
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

            let sleepActivities = activities.filter { $0.kind == .sleep }
            let sleepData = DataController.sliceDataToPlot(sleepActivities: sleepActivities)

            let startOfToday = Calendar.current.startOfDay(for: Date())

            let averageSleepTime = DataController.averageDurationPerDay(sleepData)
            let longestStretch = DataController.longestSleepStretch(sleepActivities)
            let dayNightBreakdown = DataController.dayNightSleepBreakdown(sleepActivities)

            ScrollView {
                VStack(spacing: 20) {
                    // Stats Cards Row 1
                    HStack(spacing: 16) {
                        SleepStatCard(
                            title: "AVG/DAY",
                            value: formatMinutes(averageSleepTime / 60),
                            icon: "chart.bar.fill",
                            color: .indigo
                        )
                        SleepStatCard(
                            title: "LONGEST",
                            value: formatMinutes(longestStretch?.durationMinutes ?? 0),
                            icon: "star.fill",
                            color: .yellow
                        )
                    }

                    // Day vs Night Breakdown
                    HStack(spacing: 16) {
                        SleepStatCard(
                            title: "DAY SLEEP",
                            value: formatMinutes(dayNightBreakdown.dayMinutes),
                            subtitle: "7am - 7pm",
                            icon: "sun.max.fill",
                            color: .orange
                        )
                        SleepStatCard(
                            title: "NIGHT SLEEP",
                            value: formatMinutes(dayNightBreakdown.nightMinutes),
                            subtitle: "7pm - 7am",
                            icon: "moon.fill",
                            color: .purple
                        )
                    }

                    // Day/Night Ratio Chart
                    if dayNightBreakdown.dayMinutes + dayNightBreakdown.nightMinutes > 0 {
                        VStack(alignment: .leading) {
                            Text("Day vs Night")
                                .font(.headline)
                                .padding(.horizontal)

                            Chart {
                                SectorMark(
                                    angle: .value("Minutes", dayNightBreakdown.dayMinutes),
                                    innerRadius: .ratio(0.6),
                                    angularInset: 2
                                )
                                .foregroundStyle(.orange)
                                .annotation(position: .overlay) {
                                    Text("Day")
                                        .font(.caption)
                                        .foregroundStyle(.white)
                                }

                                SectorMark(
                                    angle: .value("Minutes", dayNightBreakdown.nightMinutes),
                                    innerRadius: .ratio(0.6),
                                    angularInset: 2
                                )
                                .foregroundStyle(.purple)
                                .annotation(position: .overlay) {
                                    Text("Night")
                                        .font(.caption)
                                        .foregroundStyle(.white)
                                }
                            }
                            .frame(height: 150)
                            .padding(.horizontal)
                        }
                    }

                    // Sleep Timeline Chart
                    VStack(alignment: .leading) {
                        Text("Sleep Timeline")
                            .font(.headline)
                            .padding(.horizontal)

                        Chart {
                            ForEach(sleepData) { data in
                                let activityStartOfDay = Calendar.current.startOfDay(for: data.start)
                                let intervalToAdd = startOfToday.timeIntervalSince(activityStartOfDay)

                                BarMark(
                                    x: .value("Date", data.start, unit: .day),
                                    yStart: .value("Start time", data.start.addingTimeInterval(intervalToAdd), unit: .hour),
                                    yEnd: .value("End time", data.end.addingTimeInterval(intervalToAdd), unit: .hour)
                                )
                                .foregroundStyle(Color.indigo.gradient)
                            }
                        }
                        .frame(height: 200)
                        .chartXScale(domain: viewByOption.dateRange)
                        .chartXAxis {
                            AxisMarks(values: .automatic(desiredCount: viewByOption.chartXAxisCount))
                        }
                        .chartYAxis {
                            AxisMarks(values: .stride(by: .hour, count: 4)) { value in
                                if let date = value.as(Date.self) {
                                    AxisValueLabel(format: .dateTime.hour())
                                }
                                AxisGridLine()
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Sleep Quality Indicator
                    if let longest = longestStretch {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Longest Stretch")
                                .font(.headline)
                                .padding(.horizontal)

                            HStack {
                                Image(systemName: longest.isNightSleep ? "moon.stars.fill" : "sun.max.fill")
                                    .foregroundStyle(longest.isNightSleep ? .purple : .orange)
                                    .font(.title2)

                                VStack(alignment: .leading) {
                                    Text(formatMinutes(longest.durationMinutes))
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                    Text("\(longest.start.formatted(date: .abbreviated, time: .shortened)) - \(longest.end.formatted(date: .omitted, time: .shortened))")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()

                                SleepQualityBadge(durationMinutes: longest.durationMinutes)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }
                    }

                    // Recent Sleep List
                    VStack(alignment: .leading) {
                        Text("Recent Sleep")
                            .font(.headline)
                            .padding(.horizontal)

                        ForEach(sleepActivities.suffix(5).reversed()) { activity in
                            if let end = activity.endTimestamp {
                                let duration = end.timeIntervalSince(activity.timestamp) / 60
                                HStack {
                                    Image(systemName: Activity.sleepImage)
                                        .foregroundStyle(.indigo)
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
        .navigationTitle("Sleep")
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

struct SleepStatCard: View {
    let title: String
    let value: String
    var subtitle: String? = nil
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
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct SleepQualityBadge: View {
    let durationMinutes: Double

    var qualityLevel: (text: String, color: Color) {
        switch durationMinutes {
        case 0..<60:
            return ("Short", .orange)
        case 60..<120:
            return ("Good", .green)
        case 120..<240:
            return ("Great", .blue)
        default:
            return ("Excellent", .purple)
        }
    }

    var body: some View {
        Text(qualityLevel.text)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(qualityLevel.color.opacity(0.2))
            .foregroundStyle(qualityLevel.color)
            .cornerRadius(8)
    }
}

#Preview {
    NavigationStack {
        SleepSummaryView()
            .modelContainer(DataController.previewContainer)
    }
}
