//
//  TasselDateFormatting.swift
//  Tassel
//
//  Created by GitHub Copilot on 3/28/26.
//

import Foundation

enum TasselDateFormatting {
    static let displayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "MM/dd/yyyy"
        return formatter
    }()

    static func displayString(from date: Date) -> String {
        displayFormatter.string(from: date)
    }

    static func displayString(from rawValue: String?) -> String? {
        guard let parsedDate = parseDate(from: rawValue) else {
            let trimmedValue = rawValue?.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmedValue?.isEmpty == false ? trimmedValue : nil
        }

        return displayString(from: parsedDate)
    }

    static func parseDate(from rawValue: String?) -> Date? {
        guard let rawValue else { return nil }

        let trimmedValue = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedValue.isEmpty else { return nil }

        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = isoFormatter.date(from: trimmedValue) {
            return date
        }

        let fallbackIsoFormatter = ISO8601DateFormatter()
        fallbackIsoFormatter.formatOptions = [.withInternetDateTime]
        if let date = fallbackIsoFormatter.date(from: trimmedValue) {
            return date
        }

        let formatterCandidates: [DateFormatter] = [
            {
                let formatter = DateFormatter()
                formatter.calendar = Calendar(identifier: .gregorian)
                formatter.locale = Locale(identifier: "en_US_POSIX")
                formatter.timeZone = .current
                formatter.dateFormat = "yyyy-MM-dd"
                return formatter
            }(),
            {
                let formatter = DateFormatter()
                formatter.calendar = Calendar(identifier: .gregorian)
                formatter.locale = Locale(identifier: "en_US_POSIX")
                formatter.timeZone = .current
                formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                return formatter
            }(),
            {
                let formatter = DateFormatter()
                formatter.calendar = Calendar(identifier: .gregorian)
                formatter.locale = Locale(identifier: "en_US_POSIX")
                formatter.timeZone = .current
                formatter.dateFormat = "MM/dd/yyyy"
                return formatter
            }(),
            {
                let formatter = DateFormatter()
                formatter.calendar = Calendar(identifier: .gregorian)
                formatter.locale = Locale(identifier: "en_US_POSIX")
                formatter.timeZone = .current
                formatter.dateFormat = "MM/dd/yyyy HH:mm:ss"
                return formatter
            }(),
            {
                let formatter = DateFormatter()
                formatter.calendar = Calendar(identifier: .gregorian)
                formatter.locale = Locale(identifier: "en_US_POSIX")
                formatter.timeZone = .current
                formatter.dateFormat = "MM/dd/yyyy h:mm a"
                return formatter
            }()
        ]

        for formatter in formatterCandidates {
            if let date = formatter.date(from: trimmedValue) {
                return date
            }
        }

        if let timestamp = Double(trimmedValue) {
            if timestamp > 1_000_000_000_000 {
                return Date(timeIntervalSince1970: timestamp / 1000)
            }

            return Date(timeIntervalSince1970: timestamp)
        }

        return nil
    }
}