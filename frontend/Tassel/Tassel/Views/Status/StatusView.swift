//
//  StatusView.swift
//  Tassel
//
//  Created by Hawon Cho on 3/28/26.
//

import SwiftUI

struct StatusView: View {
    var body: some View {
        PlaceholderSection(
            title: "Status",
            subtitle: "See the current health of your account at a glance.",
            icon: "chart.line.uptrend.xyaxis"
        )
        .navigationTitle("Status")
    }
}

#Preview {
    NavigationStack {
        StatusView()
    }
}
