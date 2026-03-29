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
    @State private var roundedAmountStatusMessage: String?
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
                        subtitle: "Sending the selected file to be parsed for the rounded amount."
                    )
                }

                uploadResponseCard

                roundedAmountCard

                if isRequestingRoundedAmount {
                    loadingCard(
                        title: "Requesting rounded amount",
                        subtitle: "If it looks all correct, send the amount into your profile!"
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

            Text("If it all looks correct, request the rounded amount!")
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

            if let roundedAmountStatusMessage {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color.green.opacity(0.9))

                    Text(roundedAmountStatusMessage)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(Color.green.opacity(0.95))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(12)
                .background(Color.green.opacity(0.14))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
        .padding(20)
        .background(TasselPalette.background.opacity(0.95))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: 8)
    }

    @ViewBuilder
    private var uploadResponseCard: some View {
        if let uploadResponseText {
            if let fields = parsedUploadResponseFields(from: uploadResponseText) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Upload Response")
                                .font(.headline)
                                .foregroundColor(TasselPalette.text)

                            Text("Parsed values from your statement upload.")
                                .font(.caption)
                                .foregroundColor(TasselPalette.text.opacity(0.65))
                        }

                        Spacer()

                        Circle()
                            .fill(TasselPalette.accentGold.opacity(0.18))
                            .frame(width: 12, height: 12)
                    }

                    VStack(spacing: 0) {
                        ForEach(Array(fields.enumerated()), id: \.element.id) { index, field in
                            uploadFieldRow(field)

                            if index < fields.count - 1 {
                                Divider()
                                    .background(TasselPalette.accentGold.opacity(0.22))
                            }
                        }
                    }
                    .background(TasselPalette.accentGold.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .padding(20)
                .background(TasselPalette.background.opacity(0.95))
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: 8)
            } else {
                responseCard(
                    title: "Upload Response",
                    subtitle: "What you uploaded - and what should be rounded up",
                    body: prettifiedUploadResponseText(from: uploadResponseText)
                )
            }
        }
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

                    Text("Find what transactions you've made.")
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
                    roundedAmountStatusMessage = nil
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
            roundedAmountStatusMessage = nil
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
                fieldName: "image",
                mimeType: "image/png"
            )

            var request = TaskAPI.request(path: "/upload_transactions", method: "POST")
            request.setValue(contentType, forHTTPHeaderField: "Content-Type")

            let (responseData, response) = try await URLSession.shared.upload(for: request, from: body)
            try TaskAPI.validate(response: response)

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
            roundedAmountStatusMessage = nil
        }

        defer {
            Task { @MainActor in
                isRequestingRoundedAmount = false
            }
        }

        do {
            let requestBody = try makeRoundedAmountRequestBody(from: uploadResponseText)

            let request = TaskAPI.request(
                path: "/request",
                method: "POST",
                contentType: "application/json",
                body: requestBody
            )

            let (responseData, response) = try await URLSession.shared.data(for: request)
            try TaskAPI.validate(response: response)

            let successMessage = try roundedAmountSuccessMessage(from: responseData)

            await MainActor.run {
                roundedAmountStatusMessage = successMessage
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func roundedAmountSuccessMessage(from responseData: Data) throws -> String? {
        let jsonObject = try JSONSerialization.jsonObject(with: responseData)

        guard let payload = jsonObject as? [String: Any] else {
            return nil
        }

        let successValue = payload["success"]
        let isSuccess: Bool

        if let successBool = successValue as? Bool {
            isSuccess = successBool
        } else if let successNumber = successValue as? NSNumber {
            isSuccess = successNumber.boolValue
        } else {
            isSuccess = false
        }

        guard isSuccess else {
            return nil
        }

        if let message = payload["message"] as? String, !message.isEmpty {
            return message
        }

        return "Rounded amount request completed successfully."
    }

    private func parsedUploadResponseFields(from responseText: String) -> [UploadResponseField]? {
        guard
            let responseData = responseText.data(using: .utf8),
            let jsonObject = try? JSONSerialization.jsonObject(with: responseData),
            let payload = jsonObject as? [String: Any]
        else {
            return nil
        }

        return payload
            .map { key, value in
                UploadResponseField(key: key, value: jsonValueDisplayString(value))
            }
            .sorted { $0.key.localizedCaseInsensitiveCompare($1.key) == .orderedAscending }
    }

    private func prettifiedUploadResponseText(from responseText: String) -> String {
        guard
            let responseData = responseText.data(using: .utf8),
            let jsonObject = try? JSONSerialization.jsonObject(with: responseData),
            let prettyData = try? JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted])
        else {
            return responseText
        }

        return String(data: prettyData, encoding: .utf8) ?? responseText
    }

    private func jsonValueDisplayString(_ value: Any) -> String {
        if value is NSNull {
            return "null"
        }

        if let stringValue = value as? String {
            return stringValue
        }

        if let numberValue = value as? NSNumber {
            return numberValue.stringValue
        }

        if let boolValue = value as? Bool {
            return boolValue ? "true" : "false"
        }

        if JSONSerialization.isValidJSONObject(value),
           let valueData = try? JSONSerialization.data(withJSONObject: value, options: []),
           let valueText = String(data: valueData, encoding: .utf8) {
            return valueText
        }

        return String(describing: value)
    }

    private func uploadFieldRow(_ field: UploadResponseField) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(field.key)
                .font(.caption.weight(.semibold))
                .textCase(.uppercase)
                .foregroundColor(TasselPalette.text.opacity(0.6))

            Text(field.value)
                .font(.subheadline)
                .foregroundColor(TasselPalette.text)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
    }

    private func makeRoundedAmountRequestBody(from responseText: String) throws -> Data {
        guard let responseData = responseText.data(using: .utf8) else {
            throw RoundedAmountRequestBodyError.invalidEncoding
        }

        let jsonObject = try JSONSerialization.jsonObject(with: responseData)

        guard JSONSerialization.isValidJSONObject(jsonObject) else {
            throw RoundedAmountRequestBodyError.invalidJSON
        }

        return try JSONSerialization.data(withJSONObject: jsonObject)
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

private enum RoundedAmountRequestBodyError: LocalizedError {
    case invalidEncoding
    case invalidJSON

    var errorDescription: String? {
        switch self {
        case .invalidEncoding:
            return "Unable to encode upload response text as UTF-8."
        case .invalidJSON:
            return "Upload response is not a valid JSON object or array."
        }
    }
}

private extension Data {
    mutating func appendString(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}

private struct UploadResponseField: Identifiable {
    let id = UUID()
    let key: String
    let value: String
}

#Preview {
    NavigationStack {
        TransactionsView()
    }
}
