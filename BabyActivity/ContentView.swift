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
            .toolbar {
                Button("Sample data") {
                    let data = DataController.simulatedActivities
                    for activity in data {
                        modelContext.insert(activity)
                    }
                }
            }
        }
    }
    
    private func addSleepActivity() {
        withAnimation {
            let newSleepActivity = Activity(
                kind: .sleep,
                timestamp: Date(),
                endTimestamp: Date().addingTimeInterval(1)
            )
            
            modelContext.insert(newSleepActivity)
            //path = [newActivity]
        }
    }
    
    private func addMilkActivity() {
        withAnimation {
            let newMilkActivity = Activity(kind: .milk, timestamp: Date(), endTimestamp: Date().addingTimeInterval(1), amount: 0)
            modelContext.insert(newMilkActivity)
            //path = [newActivity]
        }
    }
    
    private func addWetDiaperActivity() {
        withAnimation {
            let newActivity = Activity(kind: .wetDiaper, timestamp: Date())
            modelContext.insert(newActivity)
        }
    }
    
    private func addDirtyDiaperActivity() {
        withAnimation {
            let newActivity = Activity(kind: .dirtyDiaper, timestamp: Date())
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
