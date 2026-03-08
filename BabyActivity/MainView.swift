//
//  MainView.swift
//  BabyActivity
//
//  Created by Zhihao Cui on 20/12/2024.
//

import SwiftUI

struct MainView: View {
    @EnvironmentObject var quickActionService: QuickActionService
    @State private var selectedTab = 0

    var body: some View {
            TabView(selection: $selectedTab) {
                DashboardView()
                    .tabItem {
                        Label("Dashboard", systemImage: "heart.text.square")
                    }
                    .tag(0)

                ContentView()
                    .tabItem {
                        Label("Activities", systemImage: "list.dash")
                    }
                    .tag(1)

                SummaryView()
                    .tabItem {
                        Label("Summary", systemImage: "chart.bar.xaxis.ascending.badge.clock")
                    }
                    .tag(2)
            }
            .onChange(of: quickActionService.pendingActionKind) { _, newKind in
                if newKind != nil {
                    selectedTab = 1
                }
            }
        }
}

#Preview {
    MainView()
        .environmentObject(QuickActionService.shared)
}
