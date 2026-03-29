//
//  TasselApp.swift
//  Tassel
//
//  Created by Hawon Cho on 3/28/26.
//

import SwiftUI

@main
struct TasselApp: App {
    @AppStorage(TaskAPI.userIDDefaultsKey) private var storedUserID: String = ""

    var body: some Scene {
        WindowGroup {
            if storedUserID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                UsernameSetupView(storedUserID: $storedUserID)
            } else {
                ContentView()
            }
        }
    }
}

private struct UsernameSetupView: View {
    @Binding var storedUserID: String
    @State private var draftUserID = ""

    private var trimmedDraft: String {
        draftUserID.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canContinue: Bool {
        !trimmedDraft.isEmpty
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 18) {
                Text("Choose a username")
                    .font(.largeTitle.bold())

                Text("This username will be saved on device and attached to every API request as the user-id header.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                TextField("Username", text: $draftUserID)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit(saveUserID)

                Button(action: saveUserID) {
                    Text("Continue")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!canContinue)

                Spacer()
            }
            .padding(24)
            .navigationBarBackButtonHidden(true)
        }
    }

    private func saveUserID() {
        guard canContinue else { return }

        TaskAPI.saveUserID(trimmedDraft)
        storedUserID = trimmedDraft
    }
}
