//
//  ActivityRow.swift
//  Tassel
//
//  Created by Hawon Cho on 3/28/26.
//

import SwiftUI

struct ActivityRow: View {
    let title: String
    let amount: String
    let subtitle: String

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(TasselPalette.text)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(TasselPalette.text.opacity(0.65))
            }

            Spacer()

            Text(amount)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(TasselPalette.text)
        }
        .padding(.vertical, 8)
    }
}
