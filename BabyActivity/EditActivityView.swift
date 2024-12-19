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
    @State var amountProxy: Int = 0
    
    var formatter = DateComponentsFormatter() {
        didSet {
            formatter.allowedUnits = [.hour, .minute]
            formatter.unitsStyle = .spellOut
        }
    }
    
    var body: some View {
        Form {
            DatePicker("At", selection: $activity.timestamp)
            specificEdits
        }
        .onAppear {
            switch activity.data {
            case .sleep(let endAt):
                dateProxy = endAt
            case .milk(let endAt, let amount):
                dateProxy = endAt
                amountProxy = amount
            case .diaperChange:
                // do nothing
                break
                
            }
        }
        .navigationTitle("Edit \(activity.kind)")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    @ViewBuilder var specificEdits: some View {
        
        switch activity.data {
        case .sleep(let endAt):
            DatePicker("Wake up", selection: $dateProxy)
                .onChange(of: dateProxy) {
                    activity.data = .sleep(endAt: dateProxy)
                }
            Text("Sleep \(formatter.string(from: activity.timestamp, to: endAt) ?? "0")")
        case .milk:
            DatePicker("Finish at", selection: $dateProxy)
                .onChange(of: dateProxy) {
                    activity.data = .milk(endAt: dateProxy, amount: amountProxy)
                }
            TextField("Amount", value: $amountProxy, format: .number)
                .onSubmit {
                    activity.data = .milk(endAt: dateProxy, amount: amountProxy)
                }
        case .diaperChange:
            EmptyView()
        }
        
    }
}

#Preview {
    NavigationStack {
        EditActivityView(activity: DataController.sleepAcitivity)
    }
}
