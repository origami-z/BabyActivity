//
//  SummaryView.swift
//  BabyActivity
//
//  Created by Zhihao Cui on 20/12/2024.
//

import SwiftUI

struct SummaryView: View {
    var body: some View {
        NavigationStack {
            List {
                NavigationLink {
                    SleepSummaryView()
                } label: {
                    VStack(alignment: .leading) {
                        Text("Sleep")
                        Text("Todo daily summary")
                    }
                }
                NavigationLink {
                    Text("Todo Milk detail")
                } label: {
                    VStack(alignment: .leading) {
                        Text("Milk")
                        Text("Todo daily summary")
                    }
                }
                NavigationLink {
                    Text("Todo diaper detail")
                } label: {
                    VStack(alignment: .leading) {
                        Text("Diaper")
                        Text("Todo daily summary")
                    }
                }
            }
            .navigationTitle("Summary")
        }
    }
}

#Preview {
    NavigationStack {
        SummaryView()
    }
}
