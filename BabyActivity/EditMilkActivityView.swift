//
//  EditMilkActivityView.swift
//  BabyActivity
//
//  Created by Zhihao Cui on 02/02/2025.
//

import SwiftUI

struct EditMilkActivityView: View {
    @ObservedObject var activity: MilkActivity
    
    @State private var dateSelection: Date
    @State private var volumnSelection: Int
    
    init(activity: MilkActivity) {
        _activity = .init(wrappedValue: activity) // todo: check whether this is correct
        _dateSelection = State(wrappedValue: activity.timestamp)
        _volumnSelection = State(wrappedValue: Int(activity.amount))
    }
    
    var body: some View {
        Form {
            DatePicker("Start At", selection: $dateSelection)
            
            Stepper(value: $volumnSelection, in: 5...300, step: 5) {
                HStack {
                    Text("Amount")
                    TextField("Amount", value: $volumnSelection, format: .number)
                        .fixedSize()
                    Text("ml").foregroundStyle(.secondary)
                }
            }
        }
        .onDisappear {
            activity.timestamp = dateSelection
            activity.amount = Int32(volumnSelection)
            
            PersistenceController.shared.save()
        }
        .navigationTitle("Edit \(activity.getKind())")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    EditMilkActivityView(activity: PersistenceController.milkActivityPreview)
}
