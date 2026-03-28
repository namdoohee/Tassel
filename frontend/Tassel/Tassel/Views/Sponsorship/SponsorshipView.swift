//
//  SponsorshipView.swift
//  Tassel
//
//  Created by Hawon Cho on 3/28/26.
//

import SwiftUI

struct SponsorshipView: View {
    var body: some View {
        PlaceholderSection(
            title: "Sponsorship",
            subtitle: "Review sponsorship opportunities and active commitments.",
            icon: "heart.fill"
        )
        .navigationTitle("Sponsorship")
    }
}

#Preview {
    NavigationStack {
        SponsorshipView()
    }
}
