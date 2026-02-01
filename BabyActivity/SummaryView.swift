//
//  SummaryView.swift
//  BabyActivity
//
//  Created by Zhihao Cui on 20/12/2024.
//

import SwiftUI

struct SummaryView: View {
    var body: some View {
        NavigationStack {
            List {
                // Profile & Settings Section
                Section("Profile & Settings") {
                    NavigationLink {
                        BabyProfileView()
                    } label: {
                        SummaryRowView(
                            title: "Baby Profiles",
                            subtitle: "Manage profiles, family sharing",
                            icon: "person.2.fill",
                            color: .blue
                        )
                    }
                }

                Section("Core Activities") {
                    NavigationLink {
                        SleepSummaryView()
                    } label: {
                        SummaryRowView(
                            title: "Sleep",
                            subtitle: "Daily patterns, day vs night breakdown",
                            icon: Activity.sleepImage,
                            color: .indigo
                        )
                    }
                    NavigationLink {
                        MilkSummaryView()
                    } label: {
                        SummaryRowView(
                            title: "Milk",
                            subtitle: "Daily intake, feeding intervals",
                            icon: Activity.milkImage,
                            color: .blue
                        )
                    }
                    NavigationLink {
                        DiaperSummaryView()
                    } label: {
                        SummaryRowView(
                            title: "Diapers",
                            subtitle: "Daily counts, time of day patterns",
                            icon: Activity.wetDiaperImage,
                            color: .cyan
                        )
                    }
                }

                Section("Development") {
                    NavigationLink {
                        TummyTimeSummaryView()
                    } label: {
                        SummaryRowView(
                            title: "Tummy Time",
                            subtitle: "Duration trends, daily goals",
                            icon: Activity.tummyTimeImage,
                            color: .green
                        )
                    }
                    NavigationLink {
                        SolidFoodSummaryView()
                    } label: {
                        SummaryRowView(
                            title: "Solid Food",
                            subtitle: "Foods introduced, reactions",
                            icon: Activity.solidFoodImage,
                            color: .orange
                        )
                    }
                }

                Section("Health") {
                    NavigationLink {
                        MedicineSummaryView()
                    } label: {
                        SummaryRowView(
                            title: "Medicine",
                            subtitle: "Medications, dosages, schedule",
                            icon: Activity.medicineImage,
                            color: .red
                        )
                    }
                    NavigationLink {
                        GrowthSummaryView()
                    } label: {
                        SummaryRowView(
                            title: "Growth",
                            subtitle: "Weight, height, head measurements",
                            icon: "chart.line.uptrend.xyaxis",
                            color: .purple
                        )
                    }
                    NavigationLink {
                        MilestoneSummaryView()
                    } label: {
                        SummaryRowView(
                            title: "Milestones",
                            subtitle: "Developmental achievements",
                            icon: "star.fill",
                            color: .yellow
                        )
                    }
                }
            }
            .navigationTitle("Summary")
        }
    }
}

struct SummaryRowView: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        SummaryView()
            .modelContainer(DataController.previewContainer)
    }
}
