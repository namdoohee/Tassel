//
//  TasksView.swift
//  Tassel
//
//  Created by Hawon Cho on 3/28/26.
//

import SwiftUI

struct TasksView: View {
    @State private var activeTask: TaskRecord?
    @State private var historyTasks: [TaskRecord] = []
    @State private var isLoadingHistory = false
    @State private var isClosingTask = false
    @State private var showingCreateTask = false
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerCard

                if let activeTask {
                    activeTaskCard(activeTask)
                } else {
                    emptyActiveTaskCard
                }

                historySection
            }
            .padding(20)
        }
        .background(TasselPalette.background)
        .navigationTitle("Tasks")
        .sheet(isPresented: $showingCreateTask) {
            NavigationStack {
                CreateTaskView { createdTask in
                    activeTask = createdTask
                    Task {
                        await loadHistory()
                    }
                }
            }
        }
        .task {
            await loadHistory()
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Tasks")
                        .font(.largeTitle.bold())
                        .foregroundColor(TasselPalette.text)

                    Text("Track the current active task, close it when finished, and review past task history.")
                        .font(.subheadline)
                        .foregroundColor(TasselPalette.text.opacity(0.72))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Button {
                    showingCreateTask = true
                } label: {
                    Label("Create Task", systemImage: "plus.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(TasselPalette.background)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 14)
                        .background(TasselPalette.accentBlack)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 8) {
                Label("Productivity", systemImage: "bolt.fill")
                Label("Achievement", systemImage: "trophy.fill")
            }
            .font(.caption.weight(.semibold))
            .foregroundColor(TasselPalette.accentBlack)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [
                    TasselPalette.background,
                    TasselPalette.accentGold.opacity(0.08)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: 8)
    }

    private func activeTaskCard(_ task: TaskRecord) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(
                title: "Current active task",
                subtitle: "Close the active task as success or failure when it is complete."
            )

            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(task.title)
                        .font(.title3.bold())
                        .foregroundColor(TasselPalette.text)

                    Text(task.type.title)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(task.type.tint)
                }

                Spacer()

                Text(task.depositAmount, format: .currency(code: "USD"))
                    .font(.headline.weight(.semibold))
                    .foregroundColor(TasselPalette.accentBlack)
            }

            Text(task.description)
                .font(.subheadline)
                .foregroundColor(TasselPalette.text.opacity(0.72))

            if let trackedAppName = task.trackedAppName, !trackedAppName.isEmpty {
                Label(trackedAppName, systemImage: "iphone.gen3")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(TasselPalette.accentBlack)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(TasselPalette.accentGold.opacity(0.12))
                    .clipShape(Capsule())
            }

            HStack(spacing: 10) {
                Button {
                    Task {
                        await closeTask(task, result: .success)
                    }
                } label: {
                    closeButtonLabel(title: "Success", systemImage: "checkmark.circle.fill", background: TasselPalette.accentGold)
                }
                .disabled(isClosingTask)

                Button {
                    Task {
                        await closeTask(task, result: .failure)
                    }
                } label: {
                    closeButtonLabel(title: "Failure", systemImage: "xmark.circle.fill", background: TasselPalette.danger)
                }
                .disabled(isClosingTask)
            }

            if isClosingTask {
                loadingRow(title: "Closing task", subtitle: "Posting the result to localhost:3000/close_task.")
            }
        }
        .padding(20)
        .background(TasselPalette.background.opacity(0.95))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: 8)
    }

    private var emptyActiveTaskCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "checklist")
                .font(.system(size: 30, weight: .semibold))
                .foregroundColor(TasselPalette.accentGold)

            Text("No active task")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(TasselPalette.text)

            Text("Create a new task to start tracking productivity or achievement goals.")
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundColor(TasselPalette.text.opacity(0.6))

            Button {
                showingCreateTask = true
            } label: {
                Text("Create Task")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(TasselPalette.background)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 14)
                    .background(TasselPalette.accentBlack)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .padding(.horizontal, 16)
        .background(TasselPalette.accentGold.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(
                title: "Task history",
                subtitle: "Loaded from localhost:3000/history_task and grouped as recent activity."
            )

            if isLoadingHistory {
                loadingRow(title: "Loading history", subtitle: "Fetching task records from the server.")
            }

            if let errorMessage {
                responseCard(
                    title: "History Error",
                    subtitle: "Unable to load the task history payload.",
                    body: errorMessage,
                    accent: TasselPalette.danger
                )
            }

            if !isLoadingHistory && errorMessage == nil && historyTasks.isEmpty {
                emptyHistoryState
            }

            ForEach(historyTasks) { task in
                historyRow(task)
            }
        }
    }

    private var emptyHistoryState: some View {
        VStack(spacing: 12) {
            Image(systemName: "clock.badge.questionmark")
                .font(.system(size: 30, weight: .semibold))
                .foregroundColor(TasselPalette.accentGold)

            Text("No history yet")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(TasselPalette.text)

            Text("Completed and closed tasks will appear here once the endpoint returns records.")
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundColor(TasselPalette.text.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .padding(.horizontal, 16)
        .background(TasselPalette.accentGold.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func historyRow(_ task: TaskRecord) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(.headline)
                        .foregroundColor(TasselPalette.text)

                    Text(task.type.title)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(task.type.tint)
                }

                Spacer()

                Text(task.status.displayTitle)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(task.status.tint)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .background(task.status.tint.opacity(0.14))
                    .clipShape(Capsule())
            }

            Text(task.description)
                .font(.caption)
                .foregroundColor(TasselPalette.text.opacity(0.68))

            HStack(spacing: 10) {
                statusPill(title: "Deposit", value: task.depositAmount.formatted(.currency(code: "USD")), tint: TasselPalette.accentGold)
                statusPill(title: "Result", value: task.result?.title ?? "Pending", tint: task.result?.tint ?? TasselPalette.accentBlack)
            }

            if let trackedAppName = task.trackedAppName, !trackedAppName.isEmpty {
                Text("Tracked app: \(trackedAppName)")
                    .font(.caption)
                    .foregroundColor(TasselPalette.text.opacity(0.65))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(TasselPalette.background.opacity(0.95))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: 8)
    }

    private func sectionHeader(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.headline)
                .foregroundColor(TasselPalette.text)

            Text(subtitle)
                .font(.caption)
                .foregroundColor(TasselPalette.text.opacity(0.65))
        }
    }

    private func loadingRow(title: String, subtitle: String) -> some View {
        HStack(spacing: 14) {
            ProgressView()
                .tint(TasselPalette.accentGold)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(TasselPalette.text)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(TasselPalette.text.opacity(0.65))
            }

            Spacer()
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(TasselPalette.background.opacity(0.95))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: 8)
    }

    private func responseCard(title: String, subtitle: String, body: String, accent: Color = TasselPalette.accentGold) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(TasselPalette.text)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(TasselPalette.text.opacity(0.65))
                }

                Spacer()

                Circle()
                    .fill(accent.opacity(0.18))
                    .frame(width: 12, height: 12)
            }

            Text(body)
                .font(.system(.footnote, design: .monospaced))
                .foregroundColor(TasselPalette.text)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(accent.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .padding(20)
        .background(TasselPalette.background.opacity(0.95))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: 8)
    }

    private func statusPill(title: String, value: String, tint: Color) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(tint)
                .frame(width: 8, height: 8)

            Text("\(title): \(value)")
                .font(.caption.weight(.semibold))
                .foregroundColor(TasselPalette.text)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(tint.opacity(0.08))
        .clipShape(Capsule())
    }

    private func closeButtonLabel(title: String, systemImage: String, background: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
            Text(title)
        }
        .font(.subheadline.weight(.semibold))
        .foregroundColor(TasselPalette.background)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(background)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func loadHistory() async {
        await MainActor.run {
            isLoadingHistory = true
            errorMessage = nil
        }

        defer {
            Task { @MainActor in
                isLoadingHistory = false
            }
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: TaskAPI.request(path: "/history_task"))
            try TaskAPI.validate(response: response)

            let items = try decodeHistoryItems(from: data)

            await MainActor.run {
                historyTasks = items

                if let serverActiveTask = items.first(where: { $0.isActive }) {
                    activeTask = serverActiveTask
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func closeTask(_ task: TaskRecord, result: TaskCloseResult) async {
        await MainActor.run {
            isClosingTask = true
            errorMessage = nil
        }

        defer {
            Task { @MainActor in
                isClosingTask = false
            }
        }

        do {
            let request = TaskAPI.request(
                path: "/close_task",
                method: "POST",
                contentType: "application/json",
                body: try JSONEncoder().encode(CloseTaskPayload(task: task, result: result))
            )

            let (_, response) = try await URLSession.shared.data(for: request)
            try TaskAPI.validate(response: response)

            await MainActor.run {
                activeTask = nil
            }

            await loadHistory()
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func decodeHistoryItems(from data: Data) throws -> [TaskRecord] {
        let decoder = JSONDecoder()

        if let items = try? decoder.decode([TaskRecord].self, from: data) {
            return items
        }

        if let envelope = try? decoder.decode(TaskHistoryEnvelope.self, from: data) {
            return envelope.tasks ?? envelope.history ?? envelope.items ?? []
        }

        throw URLError(.cannotParseResponse)
    }
}

private struct CloseTaskPayload: Encodable {
    let taskID: String
    let title: String
    let result: String

    init(task: TaskRecord, result: TaskCloseResult) {
        taskID = task.id
        title = task.title
        self.result = result.rawValue
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(taskID, forKey: .taskID)
        try container.encode(taskID, forKey: .taskId)
        try container.encode(title, forKey: .title)
        try container.encode(result, forKey: .result)
        try container.encode(result, forKey: .outcome)
    }

    private enum CodingKeys: String, CodingKey {
        case taskID = "task_id"
        case taskId
        case title
        case result
        case outcome
    }
}

#Preview {
    NavigationStack {
        TasksView()
    }
}
