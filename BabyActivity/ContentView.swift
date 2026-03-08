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
    @EnvironmentObject var quickActionService: QuickActionService
    @Query(sort: \Activity.timestamp, order: .reverse) private var activities: [Activity]
    @State private var path = [Activity]()


    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 8) {
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

                HStack {
                    Button("Food", systemImage: Activity.solidFoodImage) {
                        addSolidFoodActivity()
                    }.buttonStyle(.borderedProminent).tint(.orange)

                    Button("Tummy", systemImage: Activity.tummyTimeImage) {
                        addTummyTimeActivity()
                    }.buttonStyle(.borderedProminent).tint(.green)

                    Button("Bath", systemImage: Activity.bathTimeImage) {
                        addBathTimeActivity()
                    }.buttonStyle(.borderedProminent).tint(.cyan)

                    Button("Medicine", systemImage: Activity.medicineImage) {
                        addMedicineActivity()
                    }.buttonStyle(.borderedProminent).tint(.red)
                }
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
            .onChange(of: quickActionService.pendingActionKind) { _, newKind in
                if let kind = newKind {
                    addActivityFromQuickAction(kind: kind)
                    quickActionService.pendingActionKind = nil
                }
            }
            .onAppear {
                if let kind = quickActionService.pendingActionKind {
                    addActivityFromQuickAction(kind: kind)
                    quickActionService.pendingActionKind = nil
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

    private func addSolidFoodActivity() {
        withAnimation {
            let newActivity = Activity(kind: .solidFood, timestamp: Date(), foodType: "")
            modelContext.insert(newActivity)
        }
    }

    private func addTummyTimeActivity() {
        withAnimation {
            let newActivity = Activity(kind: .tummyTime, timestamp: Date(), endTimestamp: Date().addingTimeInterval(1))
            modelContext.insert(newActivity)
        }
    }

    private func addBathTimeActivity() {
        withAnimation {
            let newActivity = Activity(kind: .bathTime, timestamp: Date())
            modelContext.insert(newActivity)
        }
    }

    private func addMedicineActivity() {
        withAnimation {
            let newActivity = Activity(kind: .medicine, timestamp: Date(), medicineName: "", dosage: nil)
            modelContext.insert(newActivity)
        }
    }

    private func addActivityFromQuickAction(kind: ActivityKind) {
        withAnimation {
            switch kind {
            case .sleep:
                addSleepActivity()
            case .milk:
                addMilkActivity()
            case .wetDiaper:
                addWetDiaperActivity()
            case .dirtyDiaper:
                addDirtyDiaperActivity()
            case .solidFood:
                addSolidFoodActivity()
            case .tummyTime:
                addTummyTimeActivity()
            case .bathTime:
                addBathTimeActivity()
            case .medicine:
                addMedicineActivity()
            }
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
        .environmentObject(QuickActionService.shared)
}
