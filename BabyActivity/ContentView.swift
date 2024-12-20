//
//  ContentView.swift
//  BabyActivity
//
//  Created by Zhihao Cui on 19/12/2024.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Activity.timestamp, order: .reverse) private var activities: [Activity]
    @State private var path = [Activity]()


    var body: some View {
        NavigationStack(path: $path) {
            HStack {
                Button("Sleep", systemImage: Activity.sleepImage) {
                    addSleepActivity()
                }.buttonStyle(.borderedProminent)
                
                Button("Milk", systemImage: Activity.milkImage) {
                    addMilkActivity()
                }.buttonStyle(.borderedProminent)
                
                Button("Wet", systemImage: Activity.wetDiaperImage) {
                    addWetDiaperActivity()
                }.buttonStyle(.borderedProminent)
                
                Button("Dirty", systemImage: Activity.dirtyDiaperImage) {
                    addDirtyDiaperActivity()
                }.buttonStyle(.borderedProminent)
            }
            
            List {
                ForEach(activities) { activity in
                    NavigationLink {
                        EditActivityView(activity: activity)
                    } label: {
                        ActivityListItemView(activity: activity)
                    }
                }
                .onDelete(perform: deleteItems)
            }
            .navigationTitle("Activities")
        }
    }

    private func addSleepActivity() {
        withAnimation {
            let newActivity = Activity(timestamp: Date(), data: ActivityData.sleep(endAt: Date()))
            modelContext.insert(newActivity)
            //path = [newActivity]
        }
    }
    
    private func addMilkActivity() {
        withAnimation {
            let newActivity = Activity(timestamp: Date(), data: ActivityData.milk(endAt: Date(), amount: 0))
            modelContext.insert(newActivity)
            //path = [newActivity]
        }
    }
    
    private func addWetDiaperActivity() {
        withAnimation {
            let newActivity = Activity(timestamp: Date(), data: ActivityData.diaperChange(dirty: false))
            modelContext.insert(newActivity)
        }
    }
    
    private func addDirtyDiaperActivity() {
        withAnimation {
            let newActivity = Activity(timestamp: Date(), data: ActivityData.diaperChange(dirty: true))
            modelContext.insert(newActivity)
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(activities[index])
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(DataController.previewContainer)
}
