//
//  SolidFoodSummaryView.swift
//  BabyActivity
//
//  Solid food tracking with food types and allergen reactions
//

import SwiftUI
import SwiftData
import Charts

struct SolidFoodSummaryView: View {
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
            let foodActivities = activities.filter { $0.kind == .solidFood }
            let uniqueFoods = DataController.uniqueFoodsIntroduced(foodActivities)
            let foodsWithReactions = DataController.foodsWithReactions(foodActivities)
            let dailyData = DataController.solidFoodDataByDay(foodActivities)

            ScrollView {
                VStack(spacing: 20) {
                    // Stats Cards
                    HStack(spacing: 16) {
                        SolidFoodStatCard(
                            title: "FOODS TRIED",
                            value: "\(uniqueFoods.count)",
                            icon: "fork.knife",
                            color: .orange
                        )
                        SolidFoodStatCard(
                            title: "REACTIONS",
                            value: "\(foodsWithReactions.count)",
                            icon: "exclamationmark.triangle.fill",
                            color: foodsWithReactions.isEmpty ? .green : .red
                        )
                    }

                    // Daily Meals Chart
                    VStack(alignment: .leading) {
                        Text("Daily Meals")
                            .font(.headline)
                            .padding(.horizontal)

                        Chart {
                            ForEach(dailyData) { data in
                                BarMark(
                                    x: .value("Date", data.date, unit: .day),
                                    y: .value("Meals", data.mealCount)
                                )
                                .foregroundStyle(Color.orange.gradient)
                            }
                        }
                        .frame(height: 150)
                        .chartXScale(domain: viewByOption.dateRange)
                        .chartXAxis {
                            AxisMarks(values: .automatic(desiredCount: viewByOption.chartXAxisCount))
                        }
                        .padding(.horizontal)
                    }

                    // Foods Introduced
                    if !uniqueFoods.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Foods Introduced")
                                .font(.headline)
                                .padding(.horizontal)

                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 8) {
                                ForEach(uniqueFoods, id: \.self) { food in
                                    let hasReaction = foodsWithReactions.contains(food)
                                    HStack(spacing: 4) {
                                        Text(food)
                                            .font(.caption)
                                            .lineLimit(1)
                                        if hasReaction {
                                            Image(systemName: "exclamationmark.triangle.fill")
                                                .font(.caption2)
                                                .foregroundStyle(.red)
                                        }
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 6)
                                    .background(hasReaction ? Color.red.opacity(0.1) : Color.green.opacity(0.1))
                                    .foregroundStyle(hasReaction ? .red : .primary)
                                    .cornerRadius(8)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }

                    // Reactions Log
                    if !foodsWithReactions.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Foods with Reactions")
                                .font(.headline)
                                .padding(.horizontal)

                            ForEach(foodActivities.filter { $0.reactions != nil && !($0.reactions?.isEmpty ?? true) }) { activity in
                                HStack(alignment: .top) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundStyle(.red)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(activity.foodType ?? "Unknown")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        Text(activity.reactions ?? "")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        Text(activity.timestamp, style: .date)
                                            .font(.caption2)
                                            .foregroundStyle(.tertiary)
                                    }
                                    Spacer()
                                }
                                .padding()
                                .background(Color.red.opacity(0.05))
                                .cornerRadius(12)
                                .padding(.horizontal)
                            }
                        }
                    }

                    // Recent Meals
                    VStack(alignment: .leading) {
                        Text("Recent Meals")
                            .font(.headline)
                            .padding(.horizontal)

                        ForEach(foodActivities.suffix(5).reversed()) { activity in
                            HStack {
                                Image(systemName: Activity.solidFoodImage)
                                    .foregroundStyle(.orange)
                                VStack(alignment: .leading) {
                                    Text(activity.foodType ?? "Unknown")
                                        .font(.subheadline)
                                    Text(activity.timestamp, style: .relative)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                if activity.reactions != nil && !(activity.reactions?.isEmpty ?? true) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundStyle(.red)
                                        .font(.caption)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 4)
                        }
                    }
                }
                .padding(.vertical)
            }
        }
        .navigationTitle("Solid Food")
    }
}

struct SolidFoodStatCard: View {
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
        SolidFoodSummaryView()
            .modelContainer(DataController.previewContainer)
    }
}
