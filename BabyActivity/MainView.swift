//
//  MainView.swift
//  BabyActivity
//
//  Created by Zhihao Cui on 20/12/2024.
//

import SwiftUI

struct MainView: View {
    
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
            TabView {
                ContentView()
                    .tabItem {
                        Label("Activities", systemImage: "list.dash")
                    }
                    .environment(\.managedObjectContext, viewContext)

                SummaryView()
                    .tabItem {
                        Label("Summary", systemImage: "chart.bar.xaxis.ascending.badge.clock")
                    }
            }
        }
}

#Preview {
    MainView()
}
