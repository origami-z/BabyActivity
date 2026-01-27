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
