//
//  MainTabView.swift
//  Summit
//
//  Created on 2026-02-09
//

import SwiftUI
import SwiftData

struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab: Tab = .home

    enum Tab {
        case home
        case analytics
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            ContentView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(Tab.home)

            NavigationStack {
                AnalyticsView()
            }
            .tabItem {
                Label("Analytics", systemImage: "chart.line.uptrend.xyaxis")
            }
            .tag(Tab.analytics)
        }
        .tint(Color.summitOrange)
        .task {
            SeedData.seedIfNeeded(in: modelContext)
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(ModelContainer.preview)
        .environmentObject(PurchaseManager())
}
