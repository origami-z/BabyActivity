//
//  EditActivityView.swift
//  BabyActivity
//
//  Created by Zhihao Cui on 19/12/2024.
//

import SwiftUI

// https://stackoverflow.com/a/57041232
extension Optional where Wrapped == Date {
    var _bound: Date? {
        get {
            return self
        }
        set {
            self = newValue
        }
    }
    public var bound: Date {
        get {
            return _bound ?? Date(timeIntervalSince1970: 0)
        }
        set {
            _bound = newValue.timeIntervalSince1970 == 0 ? nil : newValue
        }
    }
}

struct EditActivityView: View {
    @Bindable var activity: Activity

    let formatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .brief
        return formatter
    }()

    var body: some View {
        Form {
            specificEdits

            // Validation errors section
            if !activity.validationErrors.isEmpty {
                Section {
                    ForEach(activity.validationErrors, id: \.self) { error in
                        Label(error, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                    }
                } header: {
                    Text("Validation Issues")
                }
            }
        }
        .navigationTitle("Edit \(activity.kind)")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    @ViewBuilder var specificEdits: some View {
        
        switch activity.kind {
        case .sleep:
            DatePicker("Start At", selection: $activity.timestamp)
            
            DatePicker(
                "Wake up",
//                selection: $activity.endTimestamp
                selection: Binding<Date>(get: {activity.endTimestamp ?? Date(timeIntervalSince1970: 0)}, set: {activity.endTimestamp = $0})
            )
//                .onChange(of: dateProxy) {
//                    activity.data = .sleep(endAt: dateProxy)
//                }
            HStack {
                Text("Length")
                Spacer()
                Text(formatter.string(from: activity.timestamp, to: activity.endTimestamp ?? Date(timeIntervalSince1970: 0)) ?? "0")
            }
        case .milk:
            DatePicker("Start At", selection: $activity.timestamp)
            DatePicker("Finish at", selection: Binding<Date>(get: {activity.endTimestamp ?? Date(timeIntervalSince1970: 0)}, set: {activity.endTimestamp = $0}))
//                .onChange(of: dateProxy) {
//                    activity.data = .milk(endAt: dateProxy, amount: numberProxy)
//                }
            HStack {
                Text("Length")
                Spacer()
                Text(formatter.string(from: activity.timestamp, to: activity.endTimestamp ?? Date(timeIntervalSince1970: 0)) ?? "0")
            }
            Stepper(value: Binding<Int>(get: {activity.amount ?? 0}, set: {activity.amount = $0}), in: 5...300, step: 5) {
                HStack {
                    Text("Amount")
                    TextField("Amount", value: $activity.amount, format: .number)
                        .fixedSize()
//                        .onSubmit {
//                            activity.data = .milk(endAt: dateProxy, amount: numberProxy)
//                        }
                    Text("ml").foregroundStyle(.secondary)
                }
            }
//            .onChange(of: numberProxy) {
//                activity.data = .milk(endAt: dateProxy, amount: numberProxy)
//            }
        case .dirtyDiaper:
            DatePicker("At", selection: $activity.timestamp)

        case .wetDiaper:
            DatePicker("At", selection: $activity.timestamp)

        case .solidFood:
            DatePicker("At", selection: $activity.timestamp)
            TextField("Food Type", text: Binding<String>(
                get: { activity.foodType ?? "" },
                set: { activity.foodType = $0 }
            ))
            TextField("Reactions/Notes (optional)", text: Binding<String>(
                get: { activity.reactions ?? "" },
                set: { activity.reactions = $0.isEmpty ? nil : $0 }
            ))

        case .tummyTime:
            DatePicker("Start At", selection: $activity.timestamp)
            DatePicker(
                "End At",
                selection: Binding<Date>(
                    get: { activity.endTimestamp ?? Date(timeIntervalSince1970: 0) },
                    set: { activity.endTimestamp = $0 }
                )
            )
            HStack {
                Text("Duration")
                Spacer()
                Text(formatter.string(from: activity.timestamp, to: activity.endTimestamp ?? Date(timeIntervalSince1970: 0)) ?? "0")
            }

        case .bathTime:
            DatePicker("At", selection: $activity.timestamp)
            TextField("Notes (optional)", text: Binding<String>(
                get: { activity.notes ?? "" },
                set: { activity.notes = $0.isEmpty ? nil : $0 }
            ))

        case .medicine:
            DatePicker("At", selection: $activity.timestamp)
            TextField("Medicine Name", text: Binding<String>(
                get: { activity.medicineName ?? "" },
                set: { activity.medicineName = $0 }
            ))
            TextField("Dosage (optional)", text: Binding<String>(
                get: { activity.dosage ?? "" },
                set: { activity.dosage = $0.isEmpty ? nil : $0 }
            ))
            TextField("Notes (optional)", text: Binding<String>(
                get: { activity.notes ?? "" },
                set: { activity.notes = $0.isEmpty ? nil : $0 }
            ))
        }
    }
    
}


#Preview("Sleep") {
    NavigationStack {
        EditActivityView(activity: DataController.sleepAcitivity)
    }
}

#Preview("Milk") {
    NavigationStack {
        EditActivityView(activity: DataController.milkAcitivity)
    }
}

#Preview("Wet Diaper") {
    NavigationStack {
        EditActivityView(activity: DataController.wetDiaperActivity)
    }
}

#Preview("Dirty Diaper") {
    NavigationStack {
        EditActivityView(activity: DataController.dirtyDiaperActivity)
    }
}

#Preview("Solid Food") {
    NavigationStack {
        EditActivityView(activity: DataController.solidFoodActivity)
    }
}

#Preview("Tummy Time") {
    NavigationStack {
        EditActivityView(activity: DataController.tummyTimeActivity)
    }
}

#Preview("Bath Time") {
    NavigationStack {
        EditActivityView(activity: DataController.bathTimeActivity)
    }
}

#Preview("Medicine") {
    NavigationStack {
        EditActivityView(activity: DataController.medicineActivity)
    }
}

