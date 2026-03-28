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
        .safeAreaInset(edge: .top, spacing: 0) {
            appBrandHeader
        }
        .tint(TasselPalette.accentGold)
    }

    private var appBrandHeader: some View {
        HStack(spacing: 12) {
            Image("TasselLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 34, height: 34)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text("Tassel")
                    .font(.headline.weight(.semibold))
                    .foregroundColor(TasselPalette.text)

                Text("Campus money, tasks, and status")
                    .font(.caption)
                    .foregroundColor(TasselPalette.text.opacity(0.65))
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(TasselPalette.background)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.black.opacity(0.06))
                .frame(height: 1)
        }
    }
}

#Preview {
    ContentView()
}
