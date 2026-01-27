//
//  MainView.swift
//  BabyActivity
//
//  Created by Zhihao Cui on 20/12/2024.
//

import SwiftUI

struct MainView: View {
    var body: some View {
            TabView {
                DashboardView()
                    .tabItem {
                        Label("Dashboard", systemImage: "heart.text.square")
                    }

                ContentView()
                    .tabItem {
                        Label("Activities", systemImage: "list.dash")
                    }

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
