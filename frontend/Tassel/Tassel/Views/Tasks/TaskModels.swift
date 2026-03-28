//
//  TaskModels.swift
//  Tassel
//
//  Created by GitHub Copilot on 3/28/26.
//

import SwiftUI

enum TaskAPI {
    static func endpointURL(path: String) -> URL {
        guard let url = URL(string: "http://localhost:3000\(path)") else {
            fatalError("Invalid local endpoint URL")
        }

        return url
    }

    static func validate(response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }
}

enum TaskType: String, CaseIterable, Identifiable, Codable {
    case productivity
    case achievement

    var id: String { rawValue }

    var title: String {
        switch self {
        case .productivity:
            return "Productivity"
        case .achievement:
            return "Achievement"
        }
    }

    var tint: Color {
        switch self {
        case .productivity:
            return TasselPalette.accentGold
        case .achievement:
            return TasselPalette.accentBlack
        }
    }
}

enum TaskStatus: String, CaseIterable, Codable {
    case active
    case open
    case pending
    case completed
    case closed
    case success
    case failure
    case unknown

    var isActive: Bool {
        self == .active || self == .open || self == .pending
    }

    var displayTitle: String {
        switch self {
        case .active:
            return "Active"
        case .open:
            return "Open"
        case .pending:
            return "Pending"
        case .completed:
            return "Completed"
        case .closed:
            return "Closed"
        case .success:
            return "Success"
        case .failure:
            return "Failure"
        case .unknown:
            return "Unknown"
        }
    }

    var tint: Color {
        switch self {
        case .active, .open, .pending:
            return TasselPalette.accentGold
        case .completed, .closed, .success:
            return TasselPalette.accentBlack
        case .failure:
            return TasselPalette.danger
        case .unknown:
            return TasselPalette.text.opacity(0.7)
        }
    }

    init(normalizedRawValue: String?) {
        let normalized = normalizedRawValue?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""

        switch normalized {
        case "active":
            self = .active
        case "open":
            self = .open
        case "pending":
            self = .pending
        case "completed", "complete":
            self = .completed
        case "closed", "close":
            self = .closed
        case "success", "succeeded", "passed":
            self = .success
        case "failure", "failed", "rejected":
            self = .failure
        default:
            self = .unknown
        }
    }
}

enum TaskCloseResult: String, CaseIterable, Identifiable, Codable {
    case success
    case failure

    var id: String { rawValue }

    var title: String {
        switch self {
        case .success:
            return "Success"
        case .failure:
            return "Failure"
        }
    }

    var tint: Color {
        switch self {
        case .success:
            return TasselPalette.accentGold
        case .failure:
            return TasselPalette.danger
        }
    }
}

struct TaskRecord: Identifiable, Decodable {
    let id: String
    let title: String
    let description: String
    let type: TaskType
    let depositAmount: Double
    let trackedAppName: String?
    let status: TaskStatus
    let createdAt: String?
    let closedAt: String?
    let result: TaskCloseResult?

    var isActive: Bool {
        status.isActive
    }

    init(
        id: String,
        title: String,
        description: String,
        type: TaskType,
        depositAmount: Double,
        trackedAppName: String?,
        status: TaskStatus,
        createdAt: String?,
        closedAt: String?,
        result: TaskCloseResult?
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.type = type
        self.depositAmount = depositAmount
        self.trackedAppName = trackedAppName
        self.status = status
        self.createdAt = createdAt
        self.closedAt = closedAt
        self.result = result
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let rawID = try TaskRecord.decodeString(container, keys: [.taskID, .id, .taskId, .uuid]) ?? UUID().uuidString
        let rawTitle = try TaskRecord.decodeString(container, keys: [.title, .name]) ?? "Untitled Task"
        let rawDescription = try TaskRecord.decodeString(container, keys: [.description, .details, .subtitle]) ?? ""
        let rawType = (try TaskRecord.decodeString(container, keys: [.type, .taskType, .category]))?.lowercased()
        let rawTrackedApp = try TaskRecord.decodeString(container, keys: [.trackedAppName, .trackedApp, .trackedApplication, .screenTimeApp])
        let rawStatus = try TaskRecord.decodeString(container, keys: [.status, .state, .taskStatus])
        let rawResult = try TaskRecord.decodeString(container, keys: [.result, .outcome, .closeResult])

        id = rawID
        title = rawTitle
        description = rawDescription
        type = TaskType(rawValue: rawType ?? "") ?? (rawType?.contains("achiev") == true ? .achievement : .productivity)
        depositAmount = try TaskRecord.decodeDouble(container, keys: [.depositAmount, .deposit, .amount, .taskAmount]) ?? 0
        trackedAppName = rawTrackedApp
        status = TaskStatus(normalizedRawValue: rawStatus)
        createdAt = try TaskRecord.decodeString(container, keys: [.createdAt, .created, .createdOn])
        closedAt = try TaskRecord.decodeString(container, keys: [.closedAt, .closed, .closedOn])
        result = TaskCloseResult(rawValue: (rawResult ?? "").lowercased())
    }

    private static func decodeString(_ container: KeyedDecodingContainer<CodingKeys>, keys: [CodingKeys]) throws -> String? {
        for key in keys {
            if let value = try container.decodeIfPresent(String.self, forKey: key), !value.isEmpty {
                return value
            }
        }

        return nil
    }

    private static func decodeDouble(_ container: KeyedDecodingContainer<CodingKeys>, keys: [CodingKeys]) throws -> Double? {
        for key in keys {
            if let value = try container.decodeIfPresent(Double.self, forKey: key) {
                return value
            }

            if let integerValue = try container.decodeIfPresent(Int.self, forKey: key) {
                return Double(integerValue)
            }

            if let stringValue = try container.decodeIfPresent(String.self, forKey: key), let value = Double(stringValue) {
                return value
            }
        }

        return nil
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case taskID = "task_id"
        case taskId
        case uuid
        case title
        case name
        case description
        case details
        case subtitle
        case type
        case taskType = "task_type"
        case category
        case depositAmount = "deposit_amount"
        case deposit
        case amount
        case taskAmount = "task_amount"
        case trackedAppName = "tracked_app_name"
        case trackedApp = "tracked_app"
        case trackedApplication = "tracked_application"
        case screenTimeApp = "screen_time_app"
        case status
        case state
        case taskStatus = "task_status"
        case createdAt = "created_at"
        case created
        case createdOn
        case closedAt = "closed_at"
        case closed
        case closedOn
        case result
        case outcome
        case closeResult = "close_result"
    }
}

struct CreateTaskPayload: Encodable {
    let type: TaskType
    let title: String
    let description: String
    let depositAmount: Int
    let trackScreenTime: Bool
    let trackedAppName: String?

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type.rawValue, forKey: .type)
        try container.encode(type.rawValue, forKey: .taskType)
        try container.encode(title, forKey: .title)
        try container.encode(description, forKey: .description)
        try container.encode(depositAmount, forKey: .depositAmount)
        try container.encode(depositAmount, forKey: .depositAmountCamel)
        try container.encode(trackScreenTime, forKey: .trackScreenTime)
        try container.encode(trackScreenTime, forKey: .trackScreenTimeCamel)
        try container.encodeIfPresent(trackedAppName, forKey: .trackedAppName)
        try container.encodeIfPresent(trackedAppName, forKey: .trackedApp)
    }

    private enum CodingKeys: String, CodingKey {
        case type
        case taskType = "task_type"
        case title
        case description
        case depositAmount = "deposit_amount"
        case depositAmountCamel = "depositAmount"
        case trackScreenTime = "track_screen_time"
        case trackScreenTimeCamel = "trackScreenTime"
        case trackedAppName = "tracked_app_name"
        case trackedApp = "tracked_app"
    }
}

struct TaskHistoryEnvelope: Decodable {
    let tasks: [TaskRecord]?
    let history: [TaskRecord]?
    let items: [TaskRecord]?
}