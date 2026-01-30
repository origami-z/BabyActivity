//
//  ActivityListItemView.swift
//  BabyActivity
//
//  Created by Zhihao Cui on 19/12/2024.
//

import SwiftUI

struct ActivityListItemView: View {
    @Bindable var activity: Activity
    var showContributor: Bool = true

    let formatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter
    }()

    var body: some View {
        HStack {
            Image(systemName: activity.image).symbolRenderingMode(.palette)

            VStack(alignment: .leading, spacing: 2) {
                Text(activity.shortDisplay)

                // Show contributor if available and enabled
                if showContributor, let contributorName = activity.contributorName {
                    HStack(spacing: 4) {
                        Image(systemName: "person.fill")
                            .font(.caption2)
                        Text(contributorName)
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }
            }

            Spacer()
            Text(activity.timestamp, formatter: formatter)
        }
    }
}

#Preview("Sleep") {
        ActivityListItemView(activity: DataController.sleepAcitivity)
}
#Preview("All") {
    VStack {
        ActivityListItemView(activity: DataController.sleepAcitivity)
        ActivityListItemView(activity: DataController.milkAcitivity)
        ActivityListItemView(activity: DataController.wetDiaperActivity)
        ActivityListItemView(activity: DataController.dirtyDiaperActivity)
    }
}

