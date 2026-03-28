//
//  StatusView.swift
//  Tassel
//
//  Created by Hawon Cho on 3/28/26.
//

import Charts
import SwiftUI

struct StatusView: View {
    @State private var payments: [PaymentRecord] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    private var paymentSummaries: [PaymentSummary] {
        let groupedPayments = Dictionary(grouping: payments) { payment in
            payment.paymentType
        }

        return groupedPayments
            .map { paymentType, records in
                let totalAmount = records.reduce(0) { $0 + $1.amountPerPayment }

                return PaymentSummary(
                    paymentType: paymentType,
                    totalAmount: totalAmount,
                    count: records.count,
                    color: StatusColorPalette.color(for: paymentType)
                )
            }
            .sorted { $0.totalAmount > $1.totalAmount }
    }

    private var totalAmount: Double {
        payments.reduce(0) { $0 + $1.amountPerPayment }
    }

    private var earliestPaymentDate: Date? {
        payments.compactMap(\.parsedDate).min()
    }

    private var latestPaymentDate: Date? {
        payments.compactMap(\.parsedDate).max()
    }

    private var paymentDateRangeLabel: String? {
        guard let earliestPaymentDate, let latestPaymentDate else {
            return nil
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateStyle = .medium
        formatter.timeStyle = .short

        return formatter.string(from: earliestPaymentDate) + " to " + formatter.string(from: latestPaymentDate)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                header
                summaryStrip
                chartCard
                paymentListSection

                if isLoading {
                    loadingCard
                }

                if let errorMessage {
                    responseCard(
                        title: "Status Error",
                        subtitle: "Unable to load payments from localhost:3000/status.",
                        body: errorMessage,
                        accent: TasselPalette.danger
                    )
                }

                if !isLoading && errorMessage == nil && payments.isEmpty {
                    emptyState
                }
            }
            .padding(20)
        }
        .background(TasselPalette.background)
        .navigationTitle("Status")
        .task {
            await loadStatus()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Status")
                .font(.largeTitle.bold())
                .foregroundColor(TasselPalette.text)

            Text("Review every payment returned by localhost:3000/status, then compare the mix and totals in a pie chart.")
                .font(.subheadline)
                .foregroundColor(TasselPalette.text.opacity(0.72))
                .fixedSize(horizontal: false, vertical: true)

            if let paymentDateRangeLabel {
                Text(paymentDateRangeLabel)
                    .font(.caption)
                    .foregroundColor(TasselPalette.text.opacity(0.6))
            }

            Button {
                Task {
                    await loadStatus()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                    Text(isLoading ? "Refreshing..." : "Refresh Status")
                }
                .font(.caption.weight(.semibold))
                .foregroundColor(TasselPalette.accentBlack)
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .background(TasselPalette.accentGold.opacity(0.14))
                .clipShape(Capsule())
            }
            .disabled(isLoading)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [
                    TasselPalette.background,
                    TasselPalette.accentGold.opacity(0.06)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: 8)
    }

    private var summaryStrip: some View {
        HStack(spacing: 12) {
            statusMetric(title: "Total", value: totalAmount.formatted(.currency(code: "USD")), icon: "dollarsign.circle.fill")
            statusMetric(title: "Payments", value: "\(payments.count)", icon: "list.bullet.rectangle.fill")
            statusMetric(title: "Types", value: "\(paymentSummaries.count)", icon: "chart.pie.fill")
        }
    }

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(
                title: "Payment mix",
                subtitle: "The pie chart is built from the total amount per payment type."
            )

            if paymentSummaries.isEmpty {
                emptyChartState
            } else {
                Chart(paymentSummaries) { summary in
                    SectorMark(
                        angle: .value("Amount", summary.totalAmount),
                        innerRadius: .ratio(0.62),
                        angularInset: 1.5
                    )
                    .foregroundStyle(summary.color)
                }
                .frame(height: 240)

                VStack(spacing: 10) {
                    ForEach(paymentSummaries) { summary in
                        HStack(spacing: 12) {
                            Circle()
                                .fill(summary.color)
                                .frame(width: 12, height: 12)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(summary.paymentType)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(TasselPalette.text)

                                Text("\(summary.count) payment\(summary.count == 1 ? "" : "s")")
                                    .font(.caption)
                                    .foregroundColor(TasselPalette.text.opacity(0.65))
                            }

                            Spacer()

                            Text(summary.totalAmount.formatted(.currency(code: "USD")))
                                .font(.caption.weight(.semibold))
                                .foregroundColor(TasselPalette.text)
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
        }
        .padding(20)
        .background(TasselPalette.background.opacity(0.95))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: 8)
    }

    private var paymentListSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(
                title: "Payment list",
                subtitle: "Every payment entry returned by the status endpoint, ordered as received."
            )

            if !payments.isEmpty {
                VStack(spacing: 12) {
                    ForEach(payments) { payment in
                        paymentRow(payment)
                    }
                }
            }
        }
        .padding(20)
        .background(TasselPalette.background.opacity(0.95))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: 8)
    }

    private var loadingCard: some View {
        HStack(spacing: 14) {
            ProgressView()
                .tint(TasselPalette.accentGold)

            VStack(alignment: .leading, spacing: 4) {
                Text("Loading status")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(TasselPalette.text)

                Text("Fetching the latest payment records from localhost:3000/status.")
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

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.pie")
                .font(.system(size: 30, weight: .semibold))
                .foregroundColor(TasselPalette.accentGold)

            Text("No payment records yet")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(TasselPalette.text)

            Text("When localhost:3000/status returns payments, the list and chart will populate here.")
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

    private var emptyChartState: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.pie")
                .font(.system(size: 28, weight: .semibold))
                .foregroundColor(TasselPalette.accentGold)

            Text("Chart data unavailable")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(TasselPalette.text)

            Text("The chart appears once the endpoint returns payment types and amounts.")
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

    private func statusMetric(title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.caption.weight(.semibold))
                .foregroundColor(TasselPalette.accentBlack)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(TasselPalette.text.opacity(0.65))

                Text(value)
                    .font(.headline.weight(.semibold))
                    .foregroundColor(TasselPalette.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(TasselPalette.background.opacity(0.95))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
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

    private func paymentRow(_ payment: PaymentRecord) -> some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(payment.color.opacity(0.16))
                    .frame(width: 42, height: 42)

                Text(payment.paymentTypeInitial)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(payment.color)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    Text(payment.paymentType)
                        .font(.headline)
                        .foregroundColor(TasselPalette.text)

                    Spacer()

                    Text(payment.amountPerPayment.formatted(.currency(code: "USD")))
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(TasselPalette.text)
                }

                HStack(spacing: 8) {
                    Label(payment.formattedDate, systemImage: "calendar")
                    Label(payment.id, systemImage: "number")
                }
                .font(.caption)
                .foregroundColor(TasselPalette.text.opacity(0.65))
                .lineLimit(1)
                .minimumScaleFactor(0.85)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(TasselPalette.background.opacity(0.95))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(payment.color.opacity(0.12), lineWidth: 1)
        )
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

    private func loadStatus() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }

        defer {
            Task { @MainActor in
                isLoading = false
            }
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: URLRequest(url: StatusAPI.endpointURL(path: "/status")))
            try StatusAPI.validate(response: response)

            let items = try JSONDecoder().decode([PaymentRecord].self, from: data)

            await MainActor.run {
                payments = items
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
        StatusView()
    }
}

private enum StatusAPI {
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

private struct PaymentRecord: Decodable, Identifiable {
    let id: String
    let paymentType: String
    let amountPerPayment: Double
    let rawDateTime: String?
    let parsedDate: Date?

    var paymentTypeInitial: String {
        let trimmedType = paymentType.trimmingCharacters(in: .whitespacesAndNewlines)
        return String(trimmedType.prefix(1)).uppercased()
    }

    var formattedDate: String {
        if let parsedDate {
            return parsedDate.formatted(date: .abbreviated, time: .shortened)
        }

        return rawDateTime ?? "Unknown date"
    }

    var color: Color {
        StatusColorPalette.color(for: paymentType)
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try PaymentRecord.decodeString(container, keys: [.id, .paymentID, .paymentId, .uuid]) ?? UUID().uuidString
        paymentType = try PaymentRecord.decodeString(container, keys: [.paymentType, .paymentTypeSpaced, .paymentTypeCamel, .type, .category]) ?? "Unknown"
        amountPerPayment = try PaymentRecord.decodeDouble(container, keys: [.amountPerPayment, .amountPerPaymentCamel, .amount, .paymentAmount, .value]) ?? 0

        let dateTimeString = try PaymentRecord.decodeString(container, keys: [.dateTime, .dateTimeCamel, .dateTimeSlash, .timestamp, .createdAt])
        rawDateTime = dateTimeString
        parsedDate = PaymentRecord.parseDate(from: dateTimeString)
    }

    private static func decodeString(_ container: KeyedDecodingContainer<CodingKeys>, keys: [CodingKeys]) throws -> String? {
        for key in keys {
            if let value = try container.decodeIfPresent(String.self, forKey: key), !value.isEmpty {
                return value
            }

            if let value = try container.decodeIfPresent(Int.self, forKey: key) {
                return String(value)
            }

            if let value = try container.decodeIfPresent(Double.self, forKey: key) {
                return String(value)
            }
        }

        return nil
    }

    private static func decodeDouble(_ container: KeyedDecodingContainer<CodingKeys>, keys: [CodingKeys]) throws -> Double? {
        for key in keys {
            if let value = try container.decodeIfPresent(Double.self, forKey: key) {
                return value
            }

            if let value = try container.decodeIfPresent(Int.self, forKey: key) {
                return Double(value)
            }

            if let value = try container.decodeIfPresent(String.self, forKey: key), let parsedValue = Double(value) {
                return parsedValue
            }
        }

        return nil
    }

    private static func parseDate(from rawValue: String?) -> Date? {
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
                formatter.locale = Locale(identifier: "en_US_POSIX")
                formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                return formatter
            }(),
            {
                let formatter = DateFormatter()
                formatter.locale = Locale(identifier: "en_US_POSIX")
                formatter.dateFormat = "MM/dd/yyyy HH:mm:ss"
                return formatter
            }(),
            {
                let formatter = DateFormatter()
                formatter.locale = Locale(identifier: "en_US_POSIX")
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

    private enum CodingKeys: String, CodingKey {
        case id
        case paymentID = "payment_id"
        case paymentId
        case uuid
        case paymentType = "payment_type"
        case paymentTypeSpaced = "payment type"
        case paymentTypeCamel = "paymentType"
        case type
        case category
        case amountPerPayment = "amount_per_payment"
        case amountPerPaymentCamel = "amountPerPayment"
        case amount
        case paymentAmount = "payment_amount"
        case value
        case dateTime = "date_time"
        case dateTimeCamel = "dateTime"
        case dateTimeSlash = "date/time"
        case timestamp
        case createdAt = "created_at"
    }
}

private struct PaymentSummary: Identifiable {
    let id = UUID()
    let paymentType: String
    let totalAmount: Double
    let count: Int
    let color: Color
}

private enum StatusColorPalette {
    static let colors: [Color] = [
        TasselPalette.accentGold,
        Color(red: 0.20, green: 0.38, blue: 0.72),
        Color(red: 0.21, green: 0.58, blue: 0.43),
        Color(red: 0.74, green: 0.33, blue: 0.20),
        Color(red: 0.49, green: 0.34, blue: 0.78),
        Color(red: 0.16, green: 0.52, blue: 0.62)
    ]

    static func color(for paymentType: String) -> Color {
        colors[abs(paymentType.lowercased().hashValue) % colors.count]
    }
}
