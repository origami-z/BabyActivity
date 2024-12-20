//
//  EditActivityView.swift
//  BabyActivity
//
//  Created by Zhihao Cui on 19/12/2024.
//

import SwiftUI

struct EditActivityView: View {
    @Bindable var activity: Activity
    
    @State var dateProxy: Date = Date()
    @State var numberProxy: Int = 0
    @State var boolProxy: Bool = false
    
    let formatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .brief
        return formatter
    }()
    
    var body: some View {
        Form {
            specificEdits
        }
        .onAppear {
            switch activity.data {
            case .sleep(let endAt):
                dateProxy = endAt
            case .milk(let endAt, let amount):
                dateProxy = endAt
                numberProxy = amount
            case .diaperChange(let dirty):
                boolProxy = dirty
                break
                
            }
        }
        .navigationTitle("Edit \(activity.kind)")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    @ViewBuilder var specificEdits: some View {
        
        switch activity.data {
        case .sleep(let endAt):
            DatePicker("Start At", selection: $activity.timestamp)
            DatePicker("Wake up", selection: $dateProxy)
                .onChange(of: dateProxy) {
                    activity.data = .sleep(endAt: dateProxy)
                }
            HStack {
                Text("Length")
                Spacer()
                Text(formatter.string(from: activity.timestamp, to: endAt) ?? "0")
            }
        case .milk(let endAt, _):
            DatePicker("Start At", selection: $activity.timestamp)
            DatePicker("Finish at", selection: $dateProxy)
                .onChange(of: dateProxy) {
                    activity.data = .milk(endAt: dateProxy, amount: numberProxy)
                }
            HStack {
                Text("Length")
                Spacer()
                Text(formatter.string(from: activity.timestamp, to: endAt) ?? "0")
            }
            Stepper(value: $numberProxy, in: 5...300, step: 5) {
                HStack {
                    Text("Amount")
                    TextField("Amount", value: $numberProxy, format: .number)
                        .fixedSize()
                        .onSubmit {
                            activity.data = .milk(endAt: dateProxy, amount: numberProxy)
                        }
                    Text("ml").foregroundStyle(.secondary)
                }
            }
        case .diaperChange:
            DatePicker("At", selection: $activity.timestamp)
            Picker("Kind", selection: $boolProxy) {
                Text("Wet")
                    .tag(false)
                Text("Dirty")
                    .tag(true)
            }
            .onSubmit {
                activity.data = .diaperChange(dirty: boolProxy)
            }
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

#Preview("Diaper") {
    NavigationStack {
        EditActivityView(activity: DataController.diaperAcitivity)
    }
}

