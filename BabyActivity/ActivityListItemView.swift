//
//  ActivityListItemView.swift
//  BabyActivity
//
//  Created by Zhihao Cui on 19/12/2024.
//

import SwiftUI

struct ActivityListItemView: View {
    @Bindable var activity: Activity
    
    let formatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter
    }()
    
    var body: some View {
            HStack {
                Image(systemName: activity.image).symbolRenderingMode(.palette)
                Text(activity.shortDisplay)
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

