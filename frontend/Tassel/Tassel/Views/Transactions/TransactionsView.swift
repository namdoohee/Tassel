//
//  TransactionsView.swift
//  Tassel
//
//  Created by Hawon Cho on 3/28/26.
//

import PhotosUI
import SwiftUI
import UIKit

struct TransactionsView: View {
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var selectedImageName = "purchase-statement.png"
    @State private var isUploading = false
    @State private var isRequestingRoundedAmount = false
    @State private var uploadResponseText: String?
    @State private var roundedAmountResponseText: String?
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                uploadHero
                screenshotCard
                uploadButton

                if isUploading {
                    loadingCard(
                        title: "Uploading screenshot",
                        subtitle: "Sending the selected file to localhost:3000/upload_transactions."
                    )
                }

                if let uploadResponseText {
                    responseCard(
                        title: "Upload Response",
                        subtitle: "The server response returned from the upload request.",
                        body: uploadResponseText
                    )
                }

                roundedAmountCard

                if isRequestingRoundedAmount {
                    loadingCard(
                        title: "Requesting rounded amount",
                        subtitle: "Posting the upload response to localhost:3000/request."
                    )
                }

                if let roundedAmountResponseText {
                    responseCard(
                        title: "Rounded Amount Response",
                        subtitle: "The result returned by the second request.",
                        body: roundedAmountResponseText
                    )
                }

                if let errorMessage {
                    responseCard(
                        title: "Error",
                        subtitle: "Something went wrong while processing the request.",
                        body: errorMessage,
                        accent: TasselPalette.danger
                    )
                }

                historyButton
            }
            .padding(20)
        }
        .background(TasselPalette.background)
        .onChange(of: selectedItem) { _, newValue in
            guard let newValue else { return }

            Task {
                await loadSelectedImage(from: newValue)
            }
        }
    }

    private var uploadHero: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Upload purchase statements")
                .font(.largeTitle.bold())
                .foregroundColor(TasselPalette.text)

            Text("Pick a screenshot of your purchase statements, upload it to Tassel, then deposit a rounded amount!")
                .font(.subheadline)
                .foregroundColor(TasselPalette.text.opacity(0.72))
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                Image(systemName: "arrow.up.doc")
                Text("Bank Statement Upload")
            }
            .font(.caption.weight(.semibold))
            .foregroundColor(TasselPalette.accentBlack)
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(TasselPalette.accentGold.opacity(0.14))
            .clipShape(Capsule())
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

    private var screenshotCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Screenshot")
                        .font(.headline)
                        .foregroundColor(TasselPalette.text)

                    Text(selectedImageData == nil ? "Choose a screenshot to prepare the upload." : selectedImageName)
                        .font(.caption)
                        .foregroundColor(TasselPalette.text.opacity(0.65))
                }

                Spacer()

                PhotosPicker(selection: $selectedItem, matching: .images) {
                    Label("Choose Screenshot", systemImage: "photo.on.rectangle.angled")
                        .font(.subheadline.weight(.semibold))
                }
                .buttonStyle(.bordered)
                .tint(TasselPalette.accentGold)
            }

            if let selectedUIImage {
                Image(uiImage: selectedUIImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(TasselPalette.accentGold.opacity(0.16), lineWidth: 1)
                    )
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "doc.viewfinder")
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundColor(TasselPalette.accentGold)

                    Text("No screenshot selected")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(TasselPalette.text)

                    Text("A preview will appear here after you choose an image from your library.")
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
        }
        .padding(20)
        .background(TasselPalette.background.opacity(0.95))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: 8)
    }

    private var uploadButton: some View {
        Button {
            Task {
                await uploadSelectedScreenshot()
            }
        } label: {
            HStack(spacing: 10) {
                if isUploading {
                    ProgressView()
                        .tint(TasselPalette.background)
                } else {
                    Image(systemName: "arrow.up.circle.fill")
                }

                Text(isUploading ? "Uploading..." : "Upload Statement")
            }
            .font(.headline)
            .foregroundColor(TasselPalette.background)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .padding(.horizontal, 20)
            .background(selectedImageData == nil ? TasselPalette.text.opacity(0.35) : TasselPalette.accentBlack)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .disabled(selectedImageData == nil || isUploading || isRequestingRoundedAmount)
    }

    private var roundedAmountCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Rounded Amount")
                .font(.headline)
                .foregroundColor(TasselPalette.text)

            Text("Send the response from the upload endpoint to the second API call.")
                .font(.caption)
                .foregroundColor(TasselPalette.text.opacity(0.65))

            Button {
                Task {
                    await requestRoundedAmount()
                }
            } label: {
                HStack(spacing: 10) {
                    if isRequestingRoundedAmount {
                        ProgressView()
                            .tint(TasselPalette.background)
                    } else {
                        Image(systemName: "arrow.triangle.2.circlepath")
                    }

                    Text(isRequestingRoundedAmount ? "Requesting..." : "Request Rounded Amount")
                }
                .font(.subheadline.weight(.semibold))
                .foregroundColor(TasselPalette.background)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .padding(.horizontal, 20)
                .background(uploadResponseText == nil ? TasselPalette.text.opacity(0.35) : TasselPalette.accentGold)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .disabled(uploadResponseText == nil || isUploading || isRequestingRoundedAmount)
        }
        .padding(20)
        .background(TasselPalette.background.opacity(0.95))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: 8)
    }

    private func loadingCard(title: String, subtitle: String) -> some View {
        HStack(spacing: 14) {
            ProgressView()
                .tint(TasselPalette.accentGold)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(TasselPalette.text)

                Text(subtitle)
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

    private var historyButton: some View {
        NavigationLink {
            TransactionHistoryView()
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("View transaction history")
                        .font(.headline)
                        .foregroundColor(TasselPalette.text)

                    Text("Open the recent transaction payloads returned by the server.")
                        .font(.caption)
                        .foregroundColor(TasselPalette.text.opacity(0.65))
                }

                Spacer()

                Image(systemName: "clock.arrow.circlepath")
                    .font(.headline)
                    .foregroundColor(TasselPalette.accentGold)
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(TasselPalette.background.opacity(0.95))
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: 8)
        }
        .buttonStyle(.plain)
    }

    private var selectedUIImage: UIImage? {
        guard let selectedImageData else { return nil }

        return UIImage(data: selectedImageData)
    }

    private func loadSelectedImage(from item: PhotosPickerItem) async {
        do {
            if let imageData = try await item.loadTransferable(type: Data.self) {
                await MainActor.run {
                    selectedImageData = imageData
                    selectedImageName = "purchase-statement.png"
                    uploadResponseText = nil
                    roundedAmountResponseText = nil
                    errorMessage = nil
                }
            } else {
                await MainActor.run {
                    errorMessage = "Unable to read the selected image."
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func uploadSelectedScreenshot() async {
        guard let selectedImageData else {
            await MainActor.run {
                errorMessage = "Select a screenshot before uploading."
            }
            return
        }

        await MainActor.run {
            isUploading = true
            errorMessage = nil
            roundedAmountResponseText = nil
        }

        defer {
            Task { @MainActor in
                isUploading = false
            }
        }

        do {
            let (body, contentType) = makeMultipartBody(
                fileData: selectedImageData,
                fileName: selectedImageName,
                fieldName: "file",
                mimeType: "image/png"
            )

            var request = URLRequest(url: endpointURL(path: "/upload_transactions"))
            request.httpMethod = "POST"
            request.setValue(contentType, forHTTPHeaderField: "Content-Type")

            let (responseData, response) = try await URLSession.shared.upload(for: request, from: body)
            try validate(response: response)

            let responseText = String(data: responseData, encoding: .utf8) ?? "Upload completed successfully."

            await MainActor.run {
                uploadResponseText = responseText
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func requestRoundedAmount() async {
        guard let uploadResponseText else {
            await MainActor.run {
                errorMessage = "Upload the screenshot first so the second request has data to send."
            }
            return
        }

        await MainActor.run {
            isRequestingRoundedAmount = true
            errorMessage = nil
        }

        defer {
            Task { @MainActor in
                isRequestingRoundedAmount = false
            }
        }

        do {
            var request = URLRequest(url: endpointURL(path: "/request"))
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(RoundedAmountRequestPayload(response: uploadResponseText))

            let (responseData, response) = try await URLSession.shared.data(for: request)
            try validate(response: response)

            let responseText = String(data: responseData, encoding: .utf8) ?? "Rounded amount request completed successfully."

            await MainActor.run {
                roundedAmountResponseText = responseText
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
            }
        }
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

    private func makeMultipartBody(fileData: Data, fileName: String, fieldName: String, mimeType: String) -> (body: Data, contentType: String) {
        let boundary = "Boundary-\(UUID().uuidString)"
        var body = Data()

        body.appendString("--\(boundary)\r\n")
        body.appendString("Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"\(fileName)\"\r\n")
        body.appendString("Content-Type: \(mimeType)\r\n\r\n")
        body.append(fileData)
        body.appendString("\r\n--\(boundary)--\r\n")

        return (body, "multipart/form-data; boundary=\(boundary)")
    }
}

private struct RoundedAmountRequestPayload: Encodable {
    let response: String
}

private extension Data {
    mutating func appendString(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}

#Preview {
    NavigationStack {
        TransactionsView()
    }
}
