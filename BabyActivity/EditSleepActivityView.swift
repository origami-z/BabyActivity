//
//  EditSleepActivityView.swift
//  BabyActivity
//
//  Created by Zhihao Cui on 02/02/2025.
//

import SwiftUI

struct EditSleepActivityView: View {
    @ObservedObject var activity: SleepActivity
    
    @State private var dateSelection: Date
    @State private var endDateSelection: Date
    
    init(activity: SleepActivity) {
        _activity = .init(wrappedValue: activity) // todo: check whether this is correct
        _dateSelection = State(wrappedValue: activity.timestamp)
        _endDateSelection = State(wrappedValue: activity.endTime)
    }
    
    var body: some View {
        Form {
            DatePicker("Start At", selection: $dateSelection)
            DatePicker("End at", selection: $endDateSelection)
            HStack {
                Text("Length")
                Spacer()
                Text(Formatters.sleepLengthFormatter.string(from: dateSelection, to: endDateSelection) ?? "")
            }
        }
        .onDisappear {
            activity.timestamp = dateSelection
            activity.endTime = endDateSelection
            
            PersistenceController.shared.save()
        }
        .navigationTitle("Edit \(activity.getKind())")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    EditSleepActivityView(activity: PersistenceController.sleepActivityPreview)
}
