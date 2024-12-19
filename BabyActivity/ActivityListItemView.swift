//
//  ActivityListItemView.swift
//  BabyActivity
//
//  Created by Zhihao Cui on 19/12/2024.
//

import SwiftUI

struct ActivityListItemView: View {
    @Bindable var activity: Activity
    
    var formatter = RelativeDateTimeFormatter() {
        didSet { formatter.unitsStyle = .abbreviated }
    }
    
    var body: some View {
            HStack {
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
        ActivityListItemView(activity: DataController.diaperAcitivity)
    }
}

