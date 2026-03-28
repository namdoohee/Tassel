//
//  TransactionsView.swift
//  Tassel
//
//  Created by Hawon Cho on 3/28/26.
//

import SwiftUI

struct TransactionsView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                DashboardHeader(totalBalance: 12450.82, dayChange: 42.10, dayChangePercentage: 0.34)

                VStack(alignment: .leading, spacing: 12) {
                    Text("Recent Activity")
                        .font(.headline)
                        .foregroundColor(TasselPalette.text)

                    ActivityRow(title: "Payroll Deposit", amount: "+$4,200.00", subtitle: "Today")
                    ActivityRow(title: "ETF Purchase", amount: "-$1,000.00", subtitle: "Yesterday")
                    ActivityRow(title: "Dividend Reinvested", amount: "+$32.40", subtitle: "This week")
                }
                .padding(20)
                .background(TasselPalette.background.opacity(0.95))
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: 8)
            }
            .padding(20)
        }
        .navigationTitle("Transactions")
        .background(TasselPalette.background)
    }
}

#Preview {
    NavigationStack {
        TransactionsView()
    }
}
