//
//  ContentView.swift
//  BabyActivity
//
//  Created by Zhihao Cui on 19/12/2024.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    // @State private var path = [BaseActivity]()
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \BaseActivity.timestamp, ascending: false)],
        animation: .default)
    private var activities: FetchedResults<BaseActivity>
    
    var body: some View {
        NavigationStack {
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
                    NavigationLink(value: activity) {
                        ActivityListItemView(activity: activity)
                    }
                }
                .onDelete(perform: deleteItems)
            }
            .navigationDestination(for: BaseActivity.self) { selection in
                switch selection {
                case is MilkActivity:
                    if let milkActivity = selection as? MilkActivity {
                        EditMilkActivityView(activity: milkActivity)
                    }
                case is DiaperActivity:
                    if let diaperActivity = selection as? DiaperActivity {
                        EditDiaperActivityView(activity: diaperActivity)
                    }
                case is SleepActivity:
                    if let sleepActivity = selection as? SleepActivity {
                        EditSleepActivityView(activity: sleepActivity)
                    }
                default:
                    Text("Destination view to be implemented")
                }
            }
            .navigationTitle("Activities")
            .toolbar {
                Button("Sample data") {
                    PersistenceController.addSimulatedData(viewContext: viewContext)
                }
            }
        }
    }
    
    private func saveContext() {
        do {
            try viewContext.save()
        } catch _ {
            print("Something went wrong.")
        }
    }
    
    private func addSleepActivity() {
        withAnimation {
            let _ = SleepActivity(
                context: viewContext, timestamp: Date().addingTimeInterval(-1),
                endTime: Date()
            )
            saveContext()
        }
    }
    
    private func addMilkActivity() {
        withAnimation {
            let _ = MilkActivity(
                context: viewContext,
                timestamp: Date().addingTimeInterval(-1),
                amount: 0)
            saveContext()
        }
    }
    
    private func addWetDiaperActivity() {
        withAnimation {
            let _ = DiaperActivity(
                context: viewContext,
                timestamp: Date().addingTimeInterval(-1),
                isWet: true,
                isDirty: false)
            saveContext()
        }
    }
    
    private func addDirtyDiaperActivity() {
        withAnimation {
            let _ = DiaperActivity(
                context: viewContext,
                timestamp: Date().addingTimeInterval(-1),
                isWet: false,
                isDirty: true)
            saveContext()
        }
    }
    
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map {
                activities[$0]
            }.forEach(viewContext.delete)
            saveContext()
        }
    }
}

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
