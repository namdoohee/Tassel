//
//  TasksView.swift
//  Tassel
//
//  Created by Hawon Cho on 3/28/26.
//

import SwiftUI

struct TasksView: View {
    var body: some View {
        PlaceholderSection(
            title: "Tasks",
            subtitle: "Track the work that keeps your finances organized.",
            icon: "checklist"
        )
        .navigationTitle("Tasks")
    }
}

#Preview {
    NavigationStack {
        TasksView()
    }
}
