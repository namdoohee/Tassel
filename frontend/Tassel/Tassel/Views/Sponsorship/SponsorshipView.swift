//
//  SponsorshipView.swift
//  Tassel
//
//  Created by Hawon Cho on 3/28/26.
//

import SwiftUI

struct SponsorshipView: View {
    @State private var activeTask: TaskRecord?
    @State private var currentSponsorships: [SponsorshipRecord] = []
    @State private var isLoadingActiveTask = false
    @State private var isLoadingCurrentSponsorships = false
    @State private var isRequestingSponsorship = false
    @State private var requestResponseText: String?
    @State private var shareLink: URL?
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerCard

                activeTaskCard

                requestCard

                if let shareLink {
                    shareLinkCard(shareLink)
                }

                if let requestResponseText {
                    responseCard(
                        title: "Request Response",
                        subtitle: "Raw response returned from /request_sponsorship.",
                        body: requestResponseText
                    )
                }

                currentSponsorshipsSection
            }
            .padding(20)
        }
        .background(TasselPalette.background)
        .navigationTitle("Sponsorship")
        .task {
            await refreshAll()
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sponsorship")
                .font(.largeTitle.bold())
                .foregroundColor(TasselPalette.text)

            Text("Send a sponsorship request for the current active task, share the generated link, and review your existing sponsorships.")
                .font(.subheadline)
                .foregroundColor(TasselPalette.text.opacity(0.72))
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                Label("Shareable link", systemImage: "link")
                Label("Current task", systemImage: "checklist")
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

    private var activeTaskCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(
                title: "Current active task",
                subtitle: "The sponsorship request uses the active task id resolved from localhost:3000/history_task."
            )

            if isLoadingActiveTask {
                loadingRow(title: "Loading active task", subtitle: "Fetching the latest task state from the server.")
            } else if let activeTask {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .firstTextBaseline) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(activeTask.title)
                                .font(.headline)
                                .foregroundColor(TasselPalette.text)

                            Text(activeTask.type.title)
                                .font(.caption.weight(.semibold))
                                .foregroundColor(activeTask.type.tint)
                        }

                        Spacer()

                        Text(activeTask.status.displayTitle)
                            .font(.caption.weight(.semibold))
                            .foregroundColor(activeTask.status.tint)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 10)
                            .background(activeTask.status.tint.opacity(0.14))
                            .clipShape(Capsule())
                    }

                    Text(activeTask.description)
                        .font(.subheadline)
                        .foregroundColor(TasselPalette.text.opacity(0.72))

                    HStack(spacing: 10) {
                        statusPill(title: "Task ID", value: activeTask.id, tint: TasselPalette.accentGold)
                        statusPill(title: "Deposit", value: activeTask.depositAmount.formatted(.currency(code: "USD")), tint: TasselPalette.accentBlack)
                    }

                    if let trackedAppName = activeTask.trackedAppName, !trackedAppName.isEmpty {
                        Text("Tracked app: \(trackedAppName)")
                            .font(.caption)
                            .foregroundColor(TasselPalette.text.opacity(0.65))
                    }
                }

                Button {
                    Task {
                        await sendSponsorshipRequest()
                    }
                } label: {
                    HStack(spacing: 10) {
                        if isRequestingSponsorship {
                            ProgressView()
                                .tint(TasselPalette.background)
                        } else {
                            Image(systemName: "heart.fill")
                        }

                        Text(isRequestingSponsorship ? "Requesting..." : "Request Sponsorship")
                    }
                    .font(.headline)
                    .foregroundColor(TasselPalette.background)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .padding(.horizontal, 20)
                    .background(TasselPalette.accentBlack)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .disabled(isRequestingSponsorship)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "checklist")
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundColor(TasselPalette.accentGold)

                    Text("No active task")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(TasselPalette.text)

                    Text("Create or activate a task before requesting a sponsorship link.")
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

            if let errorMessage {
                responseCard(
                    title: "Error",
                    subtitle: "Something went wrong while talking to the sponsorship endpoints.",
                    body: errorMessage,
                    accent: TasselPalette.danger
                )
            }
        }
        .padding(20)
        .background(TasselPalette.background.opacity(0.95))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: 8)
    }

    private var requestCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Request sponsorship")
                .font(.headline)
                .foregroundColor(TasselPalette.text)

            Text("POSTs the current active task id to localhost:3000/request_sponsorship and returns a link you can share.")
                .font(.caption)
                .foregroundColor(TasselPalette.text.opacity(0.65))

            Button {
                Task {
                    await sendSponsorshipRequest()
                }
            } label: {
                HStack(spacing: 10) {
                    if isRequestingSponsorship {
                        ProgressView()
                            .tint(TasselPalette.background)
                    } else {
                        Image(systemName: "paperplane.fill")
                    }

                    Text(isRequestingSponsorship ? "Sending request..." : "Send Request")
                }
                .font(.subheadline.weight(.semibold))
                .foregroundColor(TasselPalette.background)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .padding(.horizontal, 20)
                .background(activeTask == nil || isRequestingSponsorship ? TasselPalette.text.opacity(0.35) : TasselPalette.accentGold)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .disabled(activeTask == nil || isRequestingSponsorship)
        }
        .padding(20)
        .background(TasselPalette.background.opacity(0.95))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: 8)
    }

    private func shareLinkCard(_ url: URL) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Share link")
                        .font(.headline)
                        .foregroundColor(TasselPalette.text)

                    Text("Send this URL to your contacts.")
                        .font(.caption)
                        .foregroundColor(TasselPalette.text.opacity(0.65))
                }

                Spacer()

                Circle()
                    .fill(TasselPalette.accentGold.opacity(0.18))
                    .frame(width: 12, height: 12)
            }

            Text(url.absoluteString)
                .font(.system(.footnote, design: .monospaced))
                .foregroundColor(TasselPalette.text)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(TasselPalette.accentGold.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            HStack(spacing: 12) {
                ShareLink(item: url) {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(TasselPalette.background)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(TasselPalette.accentBlack)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)

                Link(destination: url) {
                    Label("Open", systemImage: "safari")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(TasselPalette.accentBlack)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(TasselPalette.accentGold.opacity(0.14))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
        }
        .padding(20)
        .background(TasselPalette.background.opacity(0.95))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: 8)
    }

    private var currentSponsorshipsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(
                title: "Current sponsorships",
                subtitle: "Loaded from localhost:3000/current_sponsorship."
            )

            Button {
                Task {
                    await loadCurrentSponsorships()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                    Text(isLoadingCurrentSponsorships ? "Refreshing..." : "Refresh Sponsorships")
                }
                .font(.caption.weight(.semibold))
                .foregroundColor(TasselPalette.accentBlack)
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .background(TasselPalette.accentGold.opacity(0.14))
                .clipShape(Capsule())
            }
            .disabled(isLoadingCurrentSponsorships)

            if isLoadingCurrentSponsorships {
                loadingRow(title: "Loading sponsorships", subtitle: "Fetching the current sponsorship payload from the server.")
            }

            if !isLoadingCurrentSponsorships && currentSponsorships.isEmpty {
                emptyState
            }

            ForEach(currentSponsorships) { sponsorship in
                sponsorshipCard(sponsorship)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "heart.text.square")
                .font(.system(size: 30, weight: .semibold))
                .foregroundColor(TasselPalette.accentGold)

            Text("No sponsorships yet")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(TasselPalette.text)

            Text("When the endpoint returns records, they will appear here.")
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

    private func sponsorshipCard(_ sponsorship: SponsorshipRecord) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(sponsorship.title)
                        .font(.headline)
                        .foregroundColor(TasselPalette.text)

                    if let taskTitle = sponsorship.taskTitle {
                        Text(taskTitle)
                            .font(.caption.weight(.semibold))
                            .foregroundColor(TasselPalette.accentBlack)
                    }
                }

                Spacer()

                if let status = sponsorship.status {
                    Text(status)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(TasselPalette.accentBlack)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                        .background(TasselPalette.accentGold.opacity(0.14))
                        .clipShape(Capsule())
                }
            }

            if let details = sponsorship.details {
                Text(details)
                    .font(.subheadline)
                    .foregroundColor(TasselPalette.text.opacity(0.72))
            }

            HStack(spacing: 10) {
                if let taskID = sponsorship.taskID {
                    statusPill(title: "Task ID", value: taskID, tint: TasselPalette.accentGold)
                }

                if let createdAt = sponsorship.createdAt {
                    statusPill(title: "Created", value: createdAt, tint: TasselPalette.accentBlack)
                }
            }

            if let shareLink = sponsorship.shareLink, let url = URL(string: shareLink) {
                Link(destination: url) {
                    Label("Open sponsorship link", systemImage: "link")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(TasselPalette.accentBlack)
                }
            } else if let link = sponsorship.shareLink {
                Text(link)
                    .font(.system(.footnote, design: .monospaced))
                    .foregroundColor(TasselPalette.text.opacity(0.7))
            }

            if let notes = sponsorship.notes {
                Text(notes)
                    .font(.caption)
                    .foregroundColor(TasselPalette.text.opacity(0.62))
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

    private func refreshAll() async {
        await loadActiveTask()
        await loadCurrentSponsorships()
    }

    private func loadActiveTask() async {
        await MainActor.run {
            isLoadingActiveTask = true
            errorMessage = nil
        }

        defer {
            Task { @MainActor in
                isLoadingActiveTask = false
            }
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: URLRequest(url: TaskAPI.endpointURL(path: "/history_task")))
            try TaskAPI.validate(response: response)

            let tasks = try decodeHistoryItems(from: data)
            let activeTask = tasks.first(where: { $0.isActive })

            await MainActor.run {
                self.activeTask = activeTask
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func sendSponsorshipRequest() async {
        guard let activeTask else {
            await MainActor.run {
                errorMessage = "No active task is available to sponsor."
            }

            return
        }

        await MainActor.run {
            isRequestingSponsorship = true
            errorMessage = nil
            requestResponseText = nil
            shareLink = nil
        }

        defer {
            Task { @MainActor in
                isRequestingSponsorship = false
            }
        }

        do {
            var request = URLRequest(url: TaskAPI.endpointURL(path: "/request_sponsorship"))
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(SponsorshipRequestPayload(task: activeTask))

            let (data, response) = try await URLSession.shared.data(for: request)
            try TaskAPI.validate(response: response)

            let responseText = prettyPrintedResponse(from: data)
            let shareURL = shareLinkURL(from: data)

            await MainActor.run {
                requestResponseText = responseText
                self.shareLink = shareURL
            }

            await loadCurrentSponsorships()
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func loadCurrentSponsorships() async {
        await MainActor.run {
            isLoadingCurrentSponsorships = true
        }

        defer {
            Task { @MainActor in
                isLoadingCurrentSponsorships = false
            }
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: URLRequest(url: TaskAPI.endpointURL(path: "/current_sponsorship")))
            try TaskAPI.validate(response: response)

            let items = try decodeCurrentSponsorships(from: data)

            await MainActor.run {
                currentSponsorships = items
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                currentSponsorships = []
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

    private func decodeCurrentSponsorships(from data: Data) throws -> [SponsorshipRecord] {
        let decoder = JSONDecoder()

        if let items = try? decoder.decode([SponsorshipRecord].self, from: data) {
            return items
        }

        if let envelope = try? decoder.decode(SponsorshipEnvelope.self, from: data) {
            return envelope.sponsorships ?? envelope.currentSponsorships ?? envelope.items ?? envelope.data ?? []
        }

        throw URLError(.cannotParseResponse)
    }

    private func shareLinkURL(from data: Data) -> URL? {
        if let response = try? JSONDecoder().decode(SponsorshipRequestResponse.self, from: data),
           let shareLink = response.resolvedLink,
           let url = URL(string: shareLink) {
            return url
        }

        guard let rawText = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
              !rawText.isEmpty
        else {
            return nil
        }

        let strippedText = rawText.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
        return URL(string: strippedText)
    }

    private func prettyPrintedResponse(from data: Data) -> String {
        guard let object = try? JSONSerialization.jsonObject(with: data) else {
            return String(data: data, encoding: .utf8) ?? "Unable to decode response body."
        }

        guard JSONSerialization.isValidJSONObject(object),
              let prettyData = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys]),
              let string = String(data: prettyData, encoding: .utf8)
        else {
            return String(describing: object)
        }

        return string
    }
}

private struct SponsorshipRequestPayload: Encodable {
    let taskID: String
    let title: String

    init(task: TaskRecord) {
        taskID = task.id
        title = task.title
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(taskID, forKey: .taskID)
        try container.encode(taskID, forKey: .taskId)
        try container.encode(taskID, forKey: .activeTaskID)
        try container.encode(taskID, forKey: .activeTaskId)
        try container.encode(title, forKey: .title)
    }

    private enum CodingKeys: String, CodingKey {
        case taskID = "task_id"
        case taskId
        case activeTaskID = "active_task_id"
        case activeTaskId
        case title
    }
}

private struct SponsorshipRequestResponse: Decodable {
    let link: String?
    let shareLink: String?
    let url: String?
    let sponsorshipLink: String?
    let message: String?

    var resolvedLink: String? {
        [link, shareLink, url, sponsorshipLink].compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }.first(where: { !$0.isEmpty })
    }

    init(from decoder: Decoder) throws {
        if let container = try? decoder.singleValueContainer(), let stringValue = try? container.decode(String.self) {
            link = stringValue
            shareLink = nil
            url = nil
            sponsorshipLink = nil
            message = nil
            return
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)
        link = try Self.decodeString(container, keys: [.link])
        shareLink = try Self.decodeString(container, keys: [.shareLink, .shareURL, .shareUrl])
        url = try Self.decodeString(container, keys: [.url])
        sponsorshipLink = try Self.decodeString(container, keys: [.sponsorshipLink, .sponsorshipURL, .sponsorshipUrl])
        message = try Self.decodeString(container, keys: [.message, .detail, .status])
    }

    private static func decodeString(_ container: KeyedDecodingContainer<CodingKeys>, keys: [CodingKeys]) throws -> String? {
        for key in keys {
            if let value = try container.decodeIfPresent(String.self, forKey: key), !value.isEmpty {
                return value
            }
        }

        return nil
    }

    private enum CodingKeys: String, CodingKey {
        case link
        case shareLink = "share_link"
        case shareURL = "share_url"
        case shareUrl = "shareUrl"
        case url
        case sponsorshipLink = "sponsorship_link"
        case sponsorshipURL = "sponsorship_url"
        case sponsorshipUrl = "sponsorshipUrl"
        case message
        case detail
        case status
    }
}

private struct SponsorshipEnvelope: Decodable {
    let sponsorships: [SponsorshipRecord]?
    let currentSponsorships: [SponsorshipRecord]?
    let items: [SponsorshipRecord]?
    let data: [SponsorshipRecord]?
}

private struct SponsorshipRecord: Decodable, Identifiable {
    let id: String
    let title: String
    let taskID: String?
    let taskTitle: String?
    let status: String?
    let details: String?
    let shareLink: String?
    let createdAt: String?
    let notes: String?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = Self.decodeString(container, keys: [.id, .sponsorshipID, .sponsorshipId, .uuid]) ?? UUID().uuidString
        title = Self.decodeString(container, keys: [.title, .name, .label, .taskTitle, .taskName]) ?? "Sponsorship"
        taskID = Self.decodeString(container, keys: [.taskID, .taskId, .activeTaskID, .activeTaskId])
        taskTitle = Self.decodeString(container, keys: [.taskTitle, .taskName, .task, .projectTitle])
        status = Self.decodeString(container, keys: [.status, .state, .phase])
        details = Self.decodeString(container, keys: [.details, .description, .body, .summary])
        shareLink = Self.decodeString(container, keys: [.shareLink, .shareURL, .shareUrl, .link, .url])
        createdAt = Self.decodeString(container, keys: [.createdAt, .created, .createdOn])
        notes = Self.decodeString(container, keys: [.notes, .note, .message])
    }

    private static func decodeString(_ container: KeyedDecodingContainer<CodingKeys>, keys: [CodingKeys]) -> String? {
        for key in keys {
            if let value = try? container.decodeIfPresent(String.self, forKey: key), !value.isEmpty {
                return value
            }
        }

        return nil
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case sponsorshipID = "sponsorship_id"
        case sponsorshipId
        case uuid
        case title
        case name
        case label
        case taskID = "task_id"
        case taskId
        case activeTaskID = "active_task_id"
        case activeTaskId
        case taskTitle = "task_title"
        case taskName = "task_name"
        case task
        case projectTitle = "project_title"
        case status
        case state
        case phase
        case details
        case description
        case body
        case summary
        case shareLink = "share_link"
        case shareURL = "share_url"
        case shareUrl = "shareUrl"
        case link
        case url
        case createdAt = "created_at"
        case created
        case createdOn
        case notes
        case note
        case message
    }
}

#Preview {
    NavigationStack {
        SponsorshipView()
    }
}
