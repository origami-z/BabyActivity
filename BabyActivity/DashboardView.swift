//
//  DashboardView.swift
//  BabyActivity
//
//  Created by Claude on 27/01/2026.
//

import SwiftUI
import SwiftData
import Charts

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Activity.timestamp, order: .reverse) private var activities: [Activity]

    @State private var selectedChartData: DailyActivitySummary?
    @State private var selectedHeatMapCell: HourlyActivityData?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Today's Summary Section
                    todaySummarySection

                    // Weekly Trend Charts Section
                    trendChartsSection

                    // Activity Heat Map Section
                    heatMapSection

                    // Highlights Section
                    highlightsSection

                    // Quick Stats Section
                    quickStatsSection
                }
                .padding()
            }
            .navigationTitle("Dashboard")
            .background(Color(.systemGroupedBackground))
        }
    }

    // MARK: - Today's Summary Section

    private var todaySummarySection: some View {
        let todayData = DataController.todaySummary(activities)
        let sleepTrend = DataController.sleepTrend(activities)
        let milkTrend = DataController.milkTrend(activities)
        let diaperTrend = DataController.diaperTrend(activities)

        return VStack(alignment: .leading, spacing: 12) {
            Text("Today")
                .font(.title2)
                .fontWeight(.bold)
                .accessibilityAddTraits(.isHeader)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                TrendStatCard(
                    title: "Sleep",
                    value: formatMinutes(todayData.sleepMinutes),
                    icon: Activity.sleepImage,
                    color: .indigo,
                    trend: sleepTrend
                )

                TrendStatCard(
                    title: "Milk",
                    value: "\(todayData.milkAmount)ml",
                    icon: Activity.milkImage,
                    color: .blue,
                    trend: milkTrend
                )

                TrendStatCard(
                    title: "Feedings",
                    value: "\(todayData.feedingCount)",
                    icon: "number",
                    color: .green,
                    trend: nil
                )

                TrendStatCard(
                    title: "Diapers",
                    value: "\(todayData.diaperCount)",
                    icon: Activity.wetDiaperImage,
                    color: .cyan,
                    trend: diaperTrend
                )
            }
        }
    }

    // MARK: - Trend Charts Section

    private var trendChartsSection: some View {
        let dailySummaries = DataController.dailyActivitySummaries(activities)
            .suffix(7)
            .map { $0 }

        return VStack(alignment: .leading, spacing: 16) {
            Text("This Week")
                .font(.title2)
                .fontWeight(.bold)
                .accessibilityAddTraits(.isHeader)

            // Sleep Trend Line Chart
            InteractiveLineChart(
                title: "Sleep",
                data: dailySummaries,
                valueKeyPath: \.sleepMinutes,
                color: .indigo,
                unit: "min",
                selectedData: $selectedChartData,
                formatValue: { formatMinutes($0) }
            )

            // Milk Trend Line Chart (using Double conversion)
            InteractiveLineChartInt(
                title: "Milk Intake",
                data: dailySummaries,
                valueKeyPath: \.milkAmount,
                color: .blue,
                unit: "ml",
                selectedData: $selectedChartData,
                formatValue: { "\(Int($0))ml" }
            )

            // Combined Activity Chart
            CombinedActivityChart(data: dailySummaries, selectedData: $selectedChartData)
        }
    }

    // MARK: - Heat Map Section

    private var heatMapSection: some View {
        let heatMapData = DataController.activityHeatMapData(activities)

        return VStack(alignment: .leading, spacing: 12) {
            Text("Activity Patterns")
                .font(.title2)
                .fontWeight(.bold)
                .accessibilityAddTraits(.isHeader)

            Text("Activities by hour and day")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            ActivityHeatMap(
                data: heatMapData,
                selectedCell: $selectedHeatMapCell
            )
        }
    }

    // MARK: - Highlights Section

    private var highlightsSection: some View {
        let highlights = DataController.generateHighlights(activities)

        return Group {
            if !highlights.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Highlights")
                        .font(.title2)
                        .fontWeight(.bold)
                        .accessibilityAddTraits(.isHeader)

                    ForEach(highlights) { highlight in
                        HighlightCard(highlight: highlight)
                    }
                }
            }
        }
    }

    // MARK: - Quick Stats Section

    private var quickStatsSection: some View {
        let weekActivities = activities.filter {
            $0.timestamp >= Date().addingTimeInterval(-7 * 24 * 60 * 60)
        }
        let longestSleep = DataController.longestSleepStretch(weekActivities)
        let avgMilkPerFeeding = DataController.averageMilkPerFeeding(weekActivities)
        let avgFeedingInterval = DataController.averageFeedingIntervalMinutes(weekActivities)

        return VStack(alignment: .leading, spacing: 12) {
            Text("Weekly Stats")
                .font(.title2)
                .fontWeight(.bold)
                .accessibilityAddTraits(.isHeader)

            VStack(spacing: 8) {
                QuickStatRow(
                    title: "Longest Sleep",
                    value: longestSleep.map { formatMinutes($0.durationMinutes) } ?? "N/A",
                    icon: "star.fill",
                    color: .yellow
                )

                QuickStatRow(
                    title: "Avg per Feeding",
                    value: "\(Int(avgMilkPerFeeding))ml",
                    icon: Activity.milkImage,
                    color: .blue
                )

                QuickStatRow(
                    title: "Feeding Interval",
                    value: formatMinutes(avgFeedingInterval),
                    icon: "clock",
                    color: .green
                )
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
        }
    }

    // MARK: - Helpers

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

// MARK: - Trend Stat Card

struct TrendStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let trend: TrendComparison?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)
                Spacer()
                if let trend = trend {
                    TrendIndicator(trend: trend)
                }
            }

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
        .accessibilityHint(trend.map { "Trend \($0.trend.accessibilityLabel)" } ?? "")
    }
}

// MARK: - Trend Indicator

struct TrendIndicator: View {
    let trend: TrendComparison

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: trend.trend.systemImage)
                .font(.caption2)
            Text("\(abs(Int(trend.percentageChange)))%")
                .font(.caption2)
        }
        .foregroundStyle(trendColor)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(trendColor.opacity(0.15))
        .cornerRadius(4)
        .accessibilityLabel("Trend \(trend.trend.accessibilityLabel) \(abs(Int(trend.percentageChange))) percent")
    }

    private var trendColor: Color {
        switch trend.trend {
        case .up: return .green
        case .down: return .red
        case .stable: return .gray
        }
    }
}

// MARK: - Interactive Line Chart

struct InteractiveLineChart: View {
    let title: String
    let data: [DailyActivitySummary]
    let valueKeyPath: KeyPath<DailyActivitySummary, Double>
    let color: Color
    let unit: String
    @Binding var selectedData: DailyActivitySummary?
    let formatValue: (Double) -> String

    @State private var rawSelectedDate: Date?

    private var selectedDataPoint: DailyActivitySummary? {
        guard let rawSelectedDate else { return nil }
        return data.first { Calendar.current.isDate($0.date, inSameDayAs: rawSelectedDate) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                if let selected = selectedDataPoint {
                    Text(formatValue(selected[keyPath: valueKeyPath]))
                        .font(.headline)
                        .foregroundStyle(color)
                        .transition(.opacity)
                }
            }

            Chart {
                ForEach(data) { item in
                    LineMark(
                        x: .value("Date", item.date, unit: .day),
                        y: .value("Value", item[keyPath: valueKeyPath])
                    )
                    .foregroundStyle(color.gradient)
                    .interpolationMethod(.catmullRom)

                    AreaMark(
                        x: .value("Date", item.date, unit: .day),
                        y: .value("Value", item[keyPath: valueKeyPath])
                    )
                    .foregroundStyle(color.opacity(0.1).gradient)
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("Date", item.date, unit: .day),
                        y: .value("Value", item[keyPath: valueKeyPath])
                    )
                    .foregroundStyle(color)
                    .symbolSize(rawSelectedDate != nil && Calendar.current.isDate(item.date, inSameDayAs: rawSelectedDate!) ? 100 : 30)
                }

                if let selected = selectedDataPoint {
                    RuleMark(x: .value("Selected", selected.date, unit: .day))
                        .foregroundStyle(color.opacity(0.5))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                        .annotation(position: .top) {
                            Text(selected.date.formatted(.dateTime.weekday(.abbreviated)))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                }
            }
            .frame(height: 150)
            .chartXSelection(value: $rawSelectedDate)
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel {
                        if let val = value.as(Double.self) {
                            Text(formatValue(val))
                                .font(.caption2)
                        }
                    }
                    AxisGridLine()
                }
            }
            .animation(.easeInOut(duration: 0.2), value: rawSelectedDate)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title) trend chart")
    }
}

// Overload for Int keypath
struct InteractiveLineChartInt: View {
    let title: String
    let data: [DailyActivitySummary]
    let valueKeyPath: KeyPath<DailyActivitySummary, Int>
    let color: Color
    let unit: String
    @Binding var selectedData: DailyActivitySummary?
    let formatValue: (Double) -> String

    @State private var rawSelectedDate: Date?

    private var selectedDataPoint: DailyActivitySummary? {
        guard let rawSelectedDate else { return nil }
        return data.first { Calendar.current.isDate($0.date, inSameDayAs: rawSelectedDate) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                if let selected = selectedDataPoint {
                    Text(formatValue(Double(selected[keyPath: valueKeyPath])))
                        .font(.headline)
                        .foregroundStyle(color)
                        .transition(.opacity)
                }
            }

            Chart {
                ForEach(data) { item in
                    LineMark(
                        x: .value("Date", item.date, unit: .day),
                        y: .value("Value", item[keyPath: valueKeyPath])
                    )
                    .foregroundStyle(color.gradient)
                    .interpolationMethod(.catmullRom)

                    AreaMark(
                        x: .value("Date", item.date, unit: .day),
                        y: .value("Value", item[keyPath: valueKeyPath])
                    )
                    .foregroundStyle(color.opacity(0.1).gradient)
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("Date", item.date, unit: .day),
                        y: .value("Value", item[keyPath: valueKeyPath])
                    )
                    .foregroundStyle(color)
                    .symbolSize(rawSelectedDate != nil && Calendar.current.isDate(item.date, inSameDayAs: rawSelectedDate!) ? 100 : 30)
                }

                if let selected = selectedDataPoint {
                    RuleMark(x: .value("Selected", selected.date, unit: .day))
                        .foregroundStyle(color.opacity(0.5))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                        .annotation(position: .top) {
                            Text(selected.date.formatted(.dateTime.weekday(.abbreviated)))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                }
            }
            .frame(height: 150)
            .chartXSelection(value: $rawSelectedDate)
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel {
                        if let val = value.as(Int.self) {
                            Text(formatValue(Double(val)))
                                .font(.caption2)
                        }
                    }
                    AxisGridLine()
                }
            }
            .animation(.easeInOut(duration: 0.2), value: rawSelectedDate)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title) trend chart")
    }
}

// MARK: - Combined Activity Chart

struct CombinedActivityChart: View {
    let data: [DailyActivitySummary]
    @Binding var selectedData: DailyActivitySummary?

    @State private var rawSelectedDate: Date?

    private var selectedDataPoint: DailyActivitySummary? {
        guard let rawSelectedDate else { return nil }
        return data.first { Calendar.current.isDate($0.date, inSameDayAs: rawSelectedDate) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Daily Overview")
                    .font(.headline)
                Spacer()
                if let selected = selectedDataPoint {
                    Text(selected.date.formatted(.dateTime.weekday(.abbreviated).day()))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Chart {
                ForEach(data) { item in
                    BarMark(
                        x: .value("Date", item.date, unit: .day),
                        y: .value("Feedings", item.feedingCount)
                    )
                    .foregroundStyle(Color.blue.gradient)
                    .position(by: .value("Type", "Feedings"))

                    BarMark(
                        x: .value("Date", item.date, unit: .day),
                        y: .value("Diapers", item.diaperCount)
                    )
                    .foregroundStyle(Color.cyan.gradient)
                    .position(by: .value("Type", "Diapers"))
                }

                if let selected = selectedDataPoint {
                    RuleMark(x: .value("Selected", selected.date, unit: .day))
                        .foregroundStyle(.gray.opacity(0.5))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                }
            }
            .frame(height: 150)
            .chartXSelection(value: $rawSelectedDate)
            .chartForegroundStyleScale([
                "Feedings": Color.blue,
                "Diapers": Color.cyan
            ])
            .chartLegend(position: .bottom, alignment: .center)
            .animation(.easeInOut(duration: 0.2), value: rawSelectedDate)

            // Selected data details
            if let selected = selectedDataPoint {
                HStack(spacing: 16) {
                    Label("\(selected.feedingCount) feedings", systemImage: Activity.milkImage)
                        .font(.caption)
                        .foregroundStyle(.blue)
                    Label("\(selected.diaperCount) diapers", systemImage: Activity.wetDiaperImage)
                        .font(.caption)
                        .foregroundStyle(.cyan)
                }
                .transition(.opacity)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Daily overview chart showing feedings and diapers")
    }
}

// MARK: - Activity Heat Map

struct ActivityHeatMap: View {
    let data: [HourlyActivityData]
    @Binding var selectedCell: HourlyActivityData?

    private let days = ["S", "M", "T", "W", "T", "F", "S"]
    private let hours = [0, 6, 12, 18]

    private var maxCount: Int {
        data.map { $0.count }.max() ?? 1
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Hour labels
            HStack(spacing: 0) {
                Text("")
                    .frame(width: 20)
                ForEach(hours, id: \.self) { hour in
                    Text(formatHour(hour))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            // Grid
            ForEach(1...7, id: \.self) { day in
                HStack(spacing: 2) {
                    Text(days[day - 1])
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(width: 20)

                    ForEach(0..<24, id: \.self) { hour in
                        let cellData = data.first { $0.dayOfWeek == day && $0.hour == hour }
                        let count = cellData?.count ?? 0

                        Rectangle()
                            .fill(colorForCount(count))
                            .frame(height: 16)
                            .cornerRadius(2)
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedCell = cellData
                                }
                            }
                            .accessibilityLabel("\(days[day - 1]) \(formatHour(hour)): \(count) activities")
                    }
                }
            }

            // Legend
            HStack(spacing: 4) {
                Text("Less")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                ForEach(0..<5, id: \.self) { level in
                    Rectangle()
                        .fill(colorForLevel(level))
                        .frame(width: 12, height: 12)
                        .cornerRadius(2)
                }
                Text("More")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 8)

            // Selected cell info
            if let selected = selectedCell {
                Text("\(days[selected.dayOfWeek - 1]) at \(formatHour(selected.hour)): \(selected.count) activities")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
                    .transition(.opacity)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }

    private func colorForCount(_ count: Int) -> Color {
        guard maxCount > 0 else { return Color(.systemGray5) }
        let ratio = Double(count) / Double(maxCount)
        return colorForLevel(Int(ratio * 4))
    }

    private func colorForLevel(_ level: Int) -> Color {
        switch level {
        case 0: return Color(.systemGray5)
        case 1: return Color.indigo.opacity(0.3)
        case 2: return Color.indigo.opacity(0.5)
        case 3: return Color.indigo.opacity(0.7)
        default: return Color.indigo
        }
    }

    private func formatHour(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "ha"
        let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date()) ?? Date()
        return formatter.string(from: date).lowercased()
    }
}

// MARK: - Highlight Card

struct HighlightCard: View {
    let highlight: ActivityHighlight

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: highlight.icon)
                .font(.title2)
                .foregroundStyle(highlight.color)
                .frame(width: 40, height: 40)
                .background(highlight.color.opacity(0.15))
                .cornerRadius(10)

            VStack(alignment: .leading, spacing: 2) {
                Text(highlight.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(highlight.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(highlight.title): \(highlight.description)")
    }
}

// MARK: - Quick Stat Row

struct QuickStatRow: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 24)

            Text(title)
                .font(.subheadline)

            Spacer()

            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }
}

// MARK: - Preview

#Preview {
    DashboardView()
        .modelContainer(DataController.previewContainer)
}
