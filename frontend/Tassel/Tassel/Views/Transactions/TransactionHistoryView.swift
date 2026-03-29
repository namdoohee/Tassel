//
//  TransactionHistoryView.swift
//  Tassel
//
//  Created by GitHub Copilot on 3/28/26.
//

import SwiftUI

struct TransactionHistoryView: View {
    @State private var historyItems: [TransactionHistoryItem] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                header

                if isLoading {
                    loadingCard
                }

                if let errorMessage {
                    responseCard(
                        title: "History Error",
                        subtitle: "Unable to load the transaction history payload.",
                        body: errorMessage,
                        accent: TasselPalette.danger
                    )
                }

                if !isLoading && errorMessage == nil && historyItems.isEmpty {
                    emptyState
                }

                ForEach(historyItems) { item in
                    TransactionHistoryRow(item: item)
                }
            }
            .padding(20)
        }
        .background(TasselPalette.background)
        .navigationTitle("History")
        .task {
            await loadTransactionHistory()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Transaction history")
                .font(.largeTitle.bold())
                .foregroundColor(TasselPalette.text)

            Text("Your previous transactions and commitments.")
                .font(.subheadline)
                .foregroundColor(TasselPalette.text.opacity(0.72))
                .fixedSize(horizontal: false, vertical: true)

            Button {
                Task {
                    await loadTransactionHistory()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                    Text(isLoading ? "Refreshing..." : "Refresh History")
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

    private var loadingCard: some View {
        HStack(spacing: 14) {
            ProgressView()
                .tint(TasselPalette.accentGold)

            VStack(alignment: .leading, spacing: 4) {
                Text("Loading history")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(TasselPalette.text)

                Text("Fetching the latest transaction records")
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
            Image(systemName: "clock.badge.questionmark")
                .font(.system(size: 30, weight: .semibold))
                .foregroundColor(TasselPalette.accentGold)

            Text("No history items yet")
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

    private func loadTransactionHistory() async {
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
            let (data, response) = try await URLSession.shared.data(for: request)
            try TaskAPI.validate(response: response)

            let items = try JSONDecoder().decode([TransactionHistoryItem].self, from: data)

            await MainActor.run {
                historyItems = items
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
            }
        }
    }

    private var request: URLRequest {
        TaskAPI.request(path: "/transaction_history")
    }
}

private struct TransactionHistoryItem: Decodable, Identifiable {
    let id: Int
    let userID: String?
    let transactionID: Int?
    let totalAmount: Double
    let roundedAmount: Double?
    let paid: Int

    enum CodingKeys: String, CodingKey {
        case id
        case userID = "user_id"
        case transactionID = "transaction_id"
        case totalAmount = "total_amount"
        case roundedAmount = "rounded_amount"
        case paid
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        guard let decodedID = try TransactionHistoryItem.decodeInt(container, keys: [.id, .transactionID]) else {
            throw DecodingError.dataCorruptedError(forKey: .id, in: container, debugDescription: "Expected an integer-compatible transaction history id.")
        }

        self.id = decodedID
        self.userID = try TransactionHistoryItem.decodeString(container, keys: [.userID])
        self.transactionID = try TransactionHistoryItem.decodeInt(container, keys: [.transactionID])
        self.totalAmount = try TransactionHistoryItem.decodeDouble(container, key: .totalAmount) ?? 0
        self.roundedAmount = try TransactionHistoryItem.decodeDouble(container, key: .roundedAmount)
        self.paid = try TransactionHistoryItem.decodeInt(container, keys: [.paid]) ?? 0
    }

    private static func decodeString(_ container: KeyedDecodingContainer<CodingKeys>, keys: [CodingKeys]) throws -> String? {
        for key in keys {
            if let value = try container.decodeIfPresent(String.self, forKey: key), !value.isEmpty {
                return value
            }

            if let intValue = try container.decodeIfPresent(Int.self, forKey: key) {
                return String(intValue)
            }

            if let doubleValue = try container.decodeIfPresent(Double.self, forKey: key) {
                return String(doubleValue)
            }
        }

        return nil
    }

    private static func decodeInt(_ container: KeyedDecodingContainer<CodingKeys>, keys: [CodingKeys]) throws -> Int? {
        for key in keys {
            if let value = try container.decodeIfPresent(Int.self, forKey: key) {
                return value
            }

            if let stringValue = try container.decodeIfPresent(String.self, forKey: key), let value = Int(stringValue) {
                return value
            }
        }

        return nil
    }

    private static func decodeDouble(_ container: KeyedDecodingContainer<CodingKeys>, key: CodingKeys) throws -> Double? {
        if let value = try container.decodeIfPresent(Double.self, forKey: key) {
            return value
        }

        if let integerValue = try container.decodeIfPresent(Int.self, forKey: key) {
            return Double(integerValue)
        }

        if let stringValue = try container.decodeIfPresent(String.self, forKey: key), let value = Double(stringValue) {
            return value
        }

        return nil
    }

    private static func decodeBool(_ container: KeyedDecodingContainer<CodingKeys>, key: CodingKeys) throws -> Bool? {
        if let value = try container.decodeIfPresent(Bool.self, forKey: key) {
            return value
        }

        if let integerValue = try container.decodeIfPresent(Int.self, forKey: key) {
            return integerValue != 0
        }

        if let stringValue = try container.decodeIfPresent(String.self, forKey: key) {
            let normalized = stringValue.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

            switch normalized {
            case "true", "1", "yes", "paid":
                return true
            case "false", "0", "no", "unpaid":
                return false
            default:
                return nil
            }
        }

        return nil
    }
}

private struct TransactionHistoryRow: View {
    let item: TransactionHistoryItem

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Amount")
                        .font(.headline)
                        .foregroundColor(TasselPalette.text)

                    Text(item.totalAmount, format: .currency(code: "USD"))
                        .font(.title3.weight(.semibold))
                        .foregroundColor(TasselPalette.text)
                }

                Spacer()

                Text(item.paid == 1 ? "Paid" : "Pending")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(item.paid == 1 ? TasselPalette.accentBlack : TasselPalette.danger)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .background((item.paid == 1 ? TasselPalette.accentGold : TasselPalette.danger).opacity(0.14))
                    .clipShape(Capsule())
            }

            HStack(spacing: 10) {
                statusPill(title: "Rounded", isEnabled: (item.roundedAmount ?? 0) > 0)
                statusPill(title: "Paid", isEnabled: item.paid == 1)
            }

            if let roundedAmount = item.roundedAmount {
                Text("Rounded Amount: \(roundedAmount, format: .currency(code: "USD"))")
                    .font(.caption.weight(.medium))
                    .foregroundColor(TasselPalette.text.opacity(0.72))
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(TasselPalette.background.opacity(0.95))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: 8)
    }

    private func statusPill(title: String, isEnabled: Bool) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(isEnabled ? TasselPalette.accentGold : TasselPalette.danger)
                .frame(width: 8, height: 8)

            Text("\(title): \(isEnabled ? "Yes" : "No")")
                .font(.caption.weight(.semibold))
                .foregroundColor(TasselPalette.text)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background((isEnabled ? TasselPalette.accentGold : TasselPalette.danger).opacity(0.08))
        .clipShape(Capsule())
    }
}

#Preview {
    NavigationStack {
        TransactionHistoryView()
    }
}