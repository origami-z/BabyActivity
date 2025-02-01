//
//  ActivityListItemView.swift
//  BabyActivity
//
//  Created by Zhihao Cui on 19/12/2024.
//

import SwiftUI
import CoreData

struct ActivityListItemView: View {
    @ObservedObject var activity: BaseActivity
    
    var body: some View {
            HStack {
                Image(systemName: activity.getImage()).symbolRenderingMode(.palette)
                Text(activity.getShortDescription())
                Spacer()
                Text(activity.timestamp, formatter: Formatters.relativeDateFormatter)
            }
    }
}

#Preview("Sleep") {
    ActivityListItemView(activity: PersistenceController.sleepActivityPreview)
}

//// Pre-set demonstration data
//extension PersistenceController {
//    var sampleItem: Item {
//        let context = Self.shared.previewInMemory.viewContext
//        let item = Item(context: context)
//        item.timestamp = Date().addingTimeInterval(30000000)
//        return item
//    }
//}


//#Preview("All") {
//    VStack {
//        ActivityListItemView(activity: DataController.sleepAcitivity)
//        ActivityListItemView(activity: DataController.milkAcitivity)
//        ActivityListItemView(activity: DataController.wetDiaperActivity)
//        ActivityListItemView(activity: DataController.dirtyDiaperActivity)
//    }
//}

