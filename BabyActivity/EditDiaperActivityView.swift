//
//  EditDiaperActivityView.swift
//  BabyActivity
//
//  Created by Zhihao Cui on 02/02/2025.
//

import SwiftUI

struct EditDiaperActivityView: View {
    @ObservedObject var activity: DiaperActivity
    
    @State private var dateSelection: Date
    @State private var isWetSelection: Bool
    @State private var isDirtySelection: Bool
    
    init(activity: DiaperActivity) {
        _activity = .init(wrappedValue: activity) // todo: check whether this is correct
        _dateSelection = State(wrappedValue: activity.timestamp)
        _isWetSelection = State(wrappedValue: activity.isWet)
        _isDirtySelection = State(wrappedValue: activity.isDirty)
    }
    
    var body: some View {
        Form {
            DatePicker("Start At", selection: $dateSelection)
            
            Toggle("Wet", isOn: $isWetSelection)
            Toggle("Dirty", isOn: $isDirtySelection)

        }
        .onDisappear {
            activity.timestamp = dateSelection
            activity.isWet = isWetSelection
            activity.isDirty = isDirtySelection
            
            PersistenceController.shared.save()
        }
        .navigationTitle("Edit \(activity.getKind())")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    EditDiaperActivityView(activity: PersistenceController.diaperActivityPreview)
}
