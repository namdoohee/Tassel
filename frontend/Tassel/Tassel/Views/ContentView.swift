//
//  ContentView.swift
//  Tassel
//
//  Created by Hawon Cho on 3/28/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            NavigationStack {
                TransactionsView()
            }
            .tabItem {
                Label("Transactions", systemImage: "arrow.left.arrow.right")
            }

            NavigationStack {
                TasksView()
            }
            .tabItem {
                Label("Tasks", systemImage: "checklist")
            }

            NavigationStack {
                SponsorshipView()
            }
            .tabItem {
                Label("Sponsorship", systemImage: "heart.fill")
            }

            NavigationStack {
                StatusView()
            }
            .tabItem {
                Label("Status", systemImage: "chart.line.uptrend.xyaxis")
            }
        }
        .tint(TasselPalette.accentGold)
    }
}

#Preview {
    ContentView()
}
