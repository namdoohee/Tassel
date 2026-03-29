//
//  CreateTaskView.swift
//  Tassel
//
//  Created by GitHub Copilot on 3/28/26.
//

import SwiftUI

struct CreateTaskView: View {
    @Environment(\.dismiss) private var dismiss

    let onCreated: (TaskRecord) -> Void

    @State private var taskType: TaskType = .productivity
    @State private var title = ""
    @State private var description = ""
    @State private var depositAmount = 25
    @State private var trackScreenTime = true
    @State private var trackedAppName = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerCard
                formCard
            }
            .padding(20)
        }
        .background(TasselPalette.background)
        .navigationTitle("Create Task")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Create Task")
                .font(.largeTitle.bold())
                .foregroundColor(TasselPalette.text)

            Text("Create and set a new active task.")
                .font(.subheadline)
                .foregroundColor(TasselPalette.text.opacity(0.72))
                .fixedSize(horizontal: false, vertical: true)
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

    private var formCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            sectionHeader(
                title: "Task details",
                subtitle: "Choose the task type, deposit, and any productivity tracking app."
            )

            Picker("Task type", selection: $taskType) {
                ForEach(TaskType.allCases) { type in
                    Text(type.title).tag(type)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: taskType) { _, newValue in
                if newValue == .achievement {
                    trackScreenTime = false
                    trackedAppName = ""
                } else {
                    trackScreenTime = true
                }
            }

            labeledTextField(title: "Title", placeholder: "Morning focus sprint", text: $title)

            VStack(alignment: .leading, spacing: 8) {
                Text("Description")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(TasselPalette.text.opacity(0.7))

                ZStack(alignment: .topLeading) {
                    if description.isEmpty {
                        Text("Explain what the student is expected to do and when it is due.")
                            .font(.subheadline)
                            .foregroundColor(TasselPalette.text.opacity(0.35))
                            .padding(.horizontal, 18)
                            .padding(.vertical, 16)
                    }

                    TextEditor(text: $description)
                        .frame(minHeight: 120)
                        .scrollContentBackground(.hidden)
                        .padding(10)
                }
                .background(TasselPalette.accentGold.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Deposit amount")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(TasselPalette.text.opacity(0.7))

                    Spacer()

                    Text(depositAmount, format: .currency(code: "USD"))
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(TasselPalette.accentBlack)
                }

                Stepper(value: $depositAmount, in: 0...500, step: 5) {
                    Text("Choose the amount the student deposits.")
                        .font(.caption)
                        .foregroundColor(TasselPalette.text.opacity(0.6))
                }
            }

            if taskType == .productivity {
                VStack(alignment: .leading, spacing: 14) {
                    Toggle("Track app screen time", isOn: $trackScreenTime)
                        .tint(TasselPalette.accentGold)

                    if trackScreenTime {
                        labeledTextField(
                            title: "Tracked app",
                            placeholder: "YouTube, TikTok, Instagram, or another app",
                            text: $trackedAppName
                        )
                    }
                }
                .padding(16)
                .background(TasselPalette.accentGold.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            }

            if let errorMessage {
                responseCard(
                    title: "Create Error",
                    subtitle: "The server rejected the request or returned an invalid response.",
                    body: errorMessage,
                    accent: TasselPalette.danger
                )
            }

            Button {
                Task {
                    await createTask()
                }
            } label: {
                HStack(spacing: 10) {
                    if isSubmitting {
                        ProgressView()
                            .tint(TasselPalette.background)
                    } else {
                        Image(systemName: "plus.circle.fill")
                    }

                    Text(isSubmitting ? "Creating..." : "Create Task")
                }
                .font(.headline)
                .foregroundColor(TasselPalette.background)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .padding(.horizontal, 20)
                .background(canSubmit ? TasselPalette.accentBlack : TasselPalette.text.opacity(0.35))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .disabled(!canSubmit || isSubmitting)
        }
        .padding(20)
        .background(TasselPalette.background.opacity(0.95))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
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

    private func labeledTextField(title: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundColor(TasselPalette.text.opacity(0.7))

            TextField(placeholder, text: text)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(TasselPalette.accentGold.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
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

    private var canSubmit: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        (!trackScreenTime || taskType == .achievement || !trackedAppName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }

    private func createTask() async {
        await MainActor.run {
            isSubmitting = true
            errorMessage = nil
        }

        defer {
            Task { @MainActor in
                isSubmitting = false
            }
        }

        do {
            let payload = CreateTaskPayload(
                type: taskType,
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                description: description.trimmingCharacters(in: .whitespacesAndNewlines),
                depositAmount: depositAmount,
                trackScreenTime: taskType == .productivity && trackScreenTime,
                trackedAppName: taskType == .productivity && trackScreenTime
                    ? trackedAppName.trimmingCharacters(in: .whitespacesAndNewlines)
                    : nil
            )

            let request = TaskAPI.request(
                path: "/create_task",
                method: "POST",
                contentType: "application/json",
                body: try JSONEncoder().encode(payload)
            )

            let (data, response) = try await URLSession.shared.data(for: request)
            try TaskAPI.validate(response: response)

            let createdTask = (try? JSONDecoder().decode(TaskRecord.self, from: data)) ?? TaskRecord(
                id: UUID().uuidString,
                title: payload.title,
                description: payload.description,
                type: payload.type,
                depositAmount: Double(payload.depositAmount),
                trackedAppName: payload.trackedAppName,
                status: .active,
                createdAt: nil,
                closedAt: nil,
                result: nil
            )

            await MainActor.run {
                onCreated(createdTask)
                dismiss()
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
            }
        }
    }
}

#Preview {
    NavigationStack {
        CreateTaskView { _ in }
    }
}