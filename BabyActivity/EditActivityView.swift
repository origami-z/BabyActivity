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
    @ObservedObject var activity: BaseActivity
    
//    @State var dateProxy: Date = Date()
//    @State var numberProxy: Int = 0
//    @State var boolProxy: Bool = false
    
    let formatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .brief
        return formatter
    }()
    
    var body: some View {
        Form {
//            specificEdits
        }
//        .onAppear {
//            switch activity.data {
//            case .sleep(let endAt):
//                dateProxy = endAt
//            case .milk(let endAt, let amount):
//                dateProxy = endAt
//                numberProxy = amount
//            case .diaperChange(let dirty):
//                boolProxy = dirty
//                break
//                
//            }
//        }
        .navigationTitle("Edit \(activity.getKind())")
        .navigationBarTitleDisplayMode(.inline)
    }
    
//    @ViewBuilder var specificEdits: some View {
//        
//        switch activity.kind {
//        case .sleep:
//            DatePicker("Start At", selection: $activity.timestamp)
//            
//            DatePicker(
//                "Wake up",
////                selection: $activity.endTimestamp
//                selection: Binding<Date>(get: {activity.endTimestamp ?? Date(timeIntervalSince1970: 0)}, set: {activity.endTimestamp = $0})
//            )
////                .onChange(of: dateProxy) {
////                    activity.data = .sleep(endAt: dateProxy)
////                }
//            HStack {
//                Text("Length")
//                Spacer()
//                Text(formatter.string(from: activity.timestamp, to: activity.endTimestamp ?? Date(timeIntervalSince1970: 0)) ?? "0")
//            }
//        case .milk:
//            DatePicker("Start At", selection: $activity.timestamp)
//            DatePicker("Finish at", selection: Binding<Date>(get: {activity.endTimestamp ?? Date(timeIntervalSince1970: 0)}, set: {activity.endTimestamp = $0}))
////                .onChange(of: dateProxy) {
////                    activity.data = .milk(endAt: dateProxy, amount: numberProxy)
////                }
//            HStack {
//                Text("Length")
//                Spacer()
//                Text(formatter.string(from: activity.timestamp, to: activity.endTimestamp ?? Date(timeIntervalSince1970: 0)) ?? "0")
//            }
//            Stepper(value: Binding<Int>(get: {activity.amount ?? 0}, set: {activity.amount = $0}), in: 5...300, step: 5) {
//                HStack {
//                    Text("Amount")
//                    TextField("Amount", value: $activity.amount, format: .number)
//                        .fixedSize()
////                        .onSubmit {
////                            activity.data = .milk(endAt: dateProxy, amount: numberProxy)
////                        }
//                    Text("ml").foregroundStyle(.secondary)
//                }
//            }
////            .onChange(of: numberProxy) {
////                activity.data = .milk(endAt: dateProxy, amount: numberProxy)
////            }
//        case .dirtyDiaper:
//            DatePicker("At", selection: $activity.timestamp)
//            
//        case .wetDiaper:
//            DatePicker("At", selection: $activity.timestamp)
//        }
//    }
    
}


#Preview("Sleep") {
    NavigationStack {
        EditActivityView(activity: PersistenceController.sleepActivityPreview)
    }
}

//#Preview("Milk") {
//    NavigationStack {
//        EditActivityView(activity: DataController.milkAcitivity)
//    }
//}
//
//#Preview("Wet Diaper") {
//    NavigationStack {
//        EditActivityView(activity: DataController.wetDiaperActivity)
//    }
//}
//
//#Preview("Dirty Diaper") {
//    NavigationStack {
//        EditActivityView(activity: DataController.dirtyDiaperActivity)
//    }
//}

