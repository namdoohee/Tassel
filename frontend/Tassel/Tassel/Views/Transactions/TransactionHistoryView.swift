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

                Text("Fetching the latest transaction records from localhost:3000/transaction_history.")
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
            try validate(response: response)

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
        URLRequest(url: endpointURL(path: "/transaction_history"))
    }

    private func endpointURL(path: String) -> URL {
        guard let url = URL(string: "http://localhost:3000\(path)") else {
            fatalError("Invalid local endpoint URL")
        }

        return url
    }

    private func validate(response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }
}

private struct TransactionHistoryItem: Decodable, Identifiable {
    let id = UUID()
    let totalAmount: Double
    let rounded: Bool
    let sent: Bool

    enum CodingKeys: String, CodingKey {
        case totalAmount = "total_amount"
        case rounded
        case sent
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

                Text(item.sent ? "Sent" : "Pending")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(item.sent ? TasselPalette.accentBlack : TasselPalette.danger)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .background((item.sent ? TasselPalette.accentGold : TasselPalette.danger).opacity(0.14))
                    .clipShape(Capsule())
            }

            HStack(spacing: 10) {
                statusPill(title: "Rounded", isEnabled: item.rounded)
                statusPill(title: "Sent", isEnabled: item.sent)
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