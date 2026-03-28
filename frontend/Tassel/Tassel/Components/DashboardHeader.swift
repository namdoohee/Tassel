//
//  DashboardHeader.swift
//  Tassel
//
//  Created by Hawon Cho on 3/28/26.
//


import SwiftUI

struct DashboardHeader: View {
    let totalBalance: Double
    let dayChange: Double
    let dayChangePercentage: Double
    
    var body: some View {
        VStack(spacing: 8) {
            // 1. Label
            Text("Total Invested")
                .font(.subheadline)
                .foregroundColor(TasselPalette.text)
            
            // 2. Main Balance
            Text(totalBalance, format: .currency(code: "USD"))
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .tracking(-1)
                .foregroundColor(TasselPalette.text)
            
            // 3. Performance Indicator
            HStack(spacing: 4) {
                Image(systemName: dayChange >= 0 ? "arrow.up.right" : "arrow.down.right")
                Text("\(dayChange, format: .currency(code: "USD")) (\(dayChangePercentage, specifier: "%.2f")%)")
            }
            .font(.footnote.bold())
            .foregroundColor(dayChange >= 0 ? TasselPalette.text : TasselPalette.danger)
            .padding(.vertical, 4)
            .padding(.horizontal, 10)
            .background(dayChange >= 0 ? TasselPalette.accentGold.opacity(0.14) : TasselPalette.danger.opacity(0.1))
            .cornerRadius(20)
            
            // 4. Quick Actions
            HStack(spacing: 20) {
                ActionButton(title: "Invest", icon: "plus.circle.fill", color: TasselPalette.accentGold)
                ActionButton(title: "Withdraw", icon: "minus.circle.fill", color: TasselPalette.accentBlack)
            }
            .padding(.top, 24)
        }
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity)
        .background(TasselPalette.background)
    }
}

// Reusable Action Button Component
struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        Button(action: { /* Action here */ }) {
            HStack {
                Image(systemName: icon)
                Text(title)
                
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(TasselPalette.background)
            .padding(.vertical, 12)
            .padding(.horizontal, 24)
            .background(color)
            .clipShape(Capsule())
            .shadow(color: color.opacity(0.3), radius: 10, x: 0, y: 5)
        }
    }
}

// Preview Provider
struct DashboardHeader_Previews: PreviewProvider {
    static var previews: some View {
        DashboardHeader(totalBalance: 12450.82, dayChange: 42.10, dayChangePercentage: 0.34)
    }
}
