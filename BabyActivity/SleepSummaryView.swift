//
//  SleepSummaryView.swift
//  BabyActivity
//
//  Created by Zhihao Cui on 20/12/2024.
//

import SwiftUI
import SwiftData
import Charts

enum ViewByOption: String, CaseIterable {
    case day
    case week
    case month
}

extension ViewByOption {
    var dateRange: ClosedRange<Date> {
        switch self {
        case .day:
            return Date().addingTimeInterval(-24 * 60 * 60)...Date()
        case .week:
            return Date().addingTimeInterval(-7 * 24 * 60 * 60)...Date()
        case .month:
            return Date().addingTimeInterval(-30 * 24 * 60 * 60)...Date()
        }
    }

    var chartXAxisCount: Int {
        switch self {
        case .day:
            return 1
        case .week:
            return 7
        case .month:
            return 5
        }
    }
}

// https://stackoverflow.com/a/78116918
struct DynamicQuery<Element: PersistentModel, Content: View>: View {
    let descriptor: FetchDescriptor<Element>
    let content: ([Element]) -> Content
    
    @Query var items: [Element]
    
    init(_ descriptor: FetchDescriptor<Element>, @ViewBuilder content: @escaping ([Element]) -> Content) {
        self.descriptor = descriptor
        self.content = content
        _items = Query(descriptor)
    }
    
    var body: some View {
        content(items)
    }
}

struct SleepSummaryView: View {
    @Environment(\.modelContext) private var modelContext
    @State var viewByOption: ViewByOption = .week
    
    var dateRangeDescriptor: FetchDescriptor<Activity> {
        let dateRange = viewByOption.dateRange
        let startDate = dateRange.lowerBound
        let endDate = dateRange.upperBound

        let predicate = #Predicate<Activity> { activity in
            // data is enum, can't be used in query, only filter by time (start time)
            // can't query .kind enum here, or it will crash at runtime
            // has to use flatMap here, force unwrap doesn't work in predicate..?
            return activity.endTimestamp.flatMap{ $0 >= startDate} == true && activity.timestamp <= endDate
        }
        return FetchDescriptor<Activity>(predicate: predicate, sortBy: [SortDescriptor(\Activity.timestamp)])
    }

    
    var body: some View {
        Picker("View by", selection: $viewByOption) {
            ForEach(ViewByOption.allCases, id: \.rawValue) { option in
                Text(option.rawValue.first?.uppercased() ?? "").tag(option)
            }
        }
        .pickerStyle(.segmented)
        
        DynamicQuery(dateRangeDescriptor) { activities in
            
            let sleepActivities = activities.filter { $0.kind == .sleep }
            let sleepData = DataController.sliceDataToPlot(sleepActivities: sleepActivities)
            
            let startOfToday = Calendar.current.startOfDay(for: Date())
            
            // TODO: fix average "day" includes 2 days
            let averageSleepTime = DataController.averageDurationPerDay(sleepData)
            
            let tmv = timeval(tv_sec: Int(averageSleepTime), tv_usec: 0)
            
            VStack {
                Text("AVG TIME")
                Text(Duration(tmv)
                    .formatted(.time(pattern: .hourMinute)))
            }
            
            Chart {
                ForEach(sleepData) { data in
                    
                    let activityStartOfDay = Calendar.current.startOfDay(for: data.start)
                    let intervalToAdd = startOfToday.timeIntervalSince(activityStartOfDay)
                    // let _ = print(activity.timestamp, intervalToAdd)
                    
                    BarMark(
                        x: .value("Date", data.start, unit: .day),
                        // Option 1: Straight Date plot, y axis extend across multiple date
//                        yStart: .value("Start time",  activity.timestamp, unit: .hour),
//                        yEnd: .value("Start time",  activity.unwrapEndAt!, unit: .hour)
                        
                        // Option 2:  A hack: Shift activity date to today
                        yStart: .value("Start time",  data.start.addingTimeInterval(intervalToAdd), unit: .hour),
                        yEnd: .value("End time",  data.end.addingTimeInterval(intervalToAdd), unit: .hour)
                        // Option 3:  TimeInterval from start of day involves manual calculation / time formatting, may also miss range that cross-over midnight
//                        yStart: .value("Start time",  activity.timestamp.timeIntervalSince(Calendar.current.startOfDay(for:activity.timestamp))),
//                        yEnd: .value("Start time",  activity.unwrapEndAt!.timeIntervalSince(Calendar.current.startOfDay(for:activity.unwrapEndAt!)))
                    )
                }
            }
            .chartXScale(domain: viewByOption.dateRange)
            .chartXAxis {
                AxisMarks(
                    values: .automatic(desiredCount: viewByOption.chartXAxisCount)
                )
            }
            // Option 3: manual assignment of time
            //  .chartYScale(domain: 0...24 * 60 * 60)
            .chartYAxis {
                AxisMarks(values: .stride(by: .hour, count: 2)) { value in
                    let _ = print("AxisMarks \(value)")
                    if let date = value.as(Date.self) {
                        // let hour = Calendar.current.component(.hour, from: date)

                        AxisValueLabel(format: .dateTime.hour().minute())
                    }

                }
            }
            
            List {
                ForEach(sleepActivities) { activity in
                    Text("\(activity.kind) \(activity.timestamp)")
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        SleepSummaryView()
            .modelContainer(DataController.previewContainer)
    }
}
