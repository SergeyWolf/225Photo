//
//  GenerationResultView.swift
//  225 Photo
//
//  Created by Сергей on 04.12.2025.
//

import SwiftUI
import UIKit
import UniformTypeIdentifiers
import Photos

@available(iOS 17.0, *)
struct GenerationResultView: View {
    let imageURL: URL
    let title: String
    let prompt: String?
    let onDelete: (() -> Void)?

    @Environment(\.dismiss) private var dismiss

    @State private var uiImage: UIImage?
    @State private var imageData: Data?
    @State private var isLoadingImage = false
    @State private var loadingError: String?

    @State private var isShareSheetPresented = false
    @State private var isExportingToFiles = false
    @State private var exportDocument: ImageDocument?

    @State private var showCopyToast = false

    // MARK: - Alerts

    private enum ResultAlert: Identifiable {
        case delete
        case savedFiles
        case savedGallery
        case saveErrorFiles
        case saveErrorGallery

        var id: Int { hashValue }
    }

    @State private var activeAlert: ResultAlert?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                header

                Spacer(minLength: 0)

                contentImage
                    .padding(.horizontal, 16)

                Spacer(minLength: 16)

                if let prompt, !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    promptBox(prompt)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)
                }

                shareButton
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
            }

            if showCopyToast {
                VStack {
                    Spacer()
                    Text("Prompt copied")
                        .font(.system(size: 13, weight: .medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.black.opacity(0.9))
                        .foregroundColor(.white)
                        .cornerRadius(16)
                        .padding(.bottom, 90)
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        // загрузка завязана на imageURL — при смене URL грузим заново
        .task(id: imageURL) {
            await loadImageIfNeeded()
        }
        .sheet(isPresented: $isShareSheetPresented) {
            if let image = uiImage {
                ImageShareSheet(items: [image])
            } else if let data = imageData {
                ImageShareSheet(items: [data])
            }
        }
        .fileExporter(
            isPresented: $isExportingToFiles,
            document: exportDocument,
            contentType: .jpeg,
            defaultFilename: "225photo-\(Int(Date().timeIntervalSince1970))"
        ) { result in
            // результат выбора директории / сохранения
            switch result {
            case .success:
                activeAlert = .savedFiles
            case .failure:
                activeAlert = .saveErrorFiles
            }
        }
        .alert(item: $activeAlert) { alert in
            switch alert {
            case .delete:
                return Alert(
                    title: Text("Delete the generation?"),
                    message: Text("You will not be able to restore it after deletion."),
                    primaryButton: .cancel(Text("Cancel")),
                    secondaryButton: .destructive(Text("Delete")) {
                        onDelete?()
                        dismiss()
                    }
                )

            case .savedFiles:
                return Alert(
                    title: Text("Saved to files"),
                    dismissButton: .default(Text("OK"))
                )

            case .savedGallery:
                return Alert(
                    title: Text("Saved in gallery"),
                    dismissButton: .default(Text("OK"))
                )

            case .saveErrorFiles:
                return Alert(
                    title: Text("Error, failed to save to files"),
                    message: Text("Something went wrong or the server is not responding. Try again or do it later."),
                    primaryButton: .cancel(Text("Cancel")),
                    secondaryButton: .default(Text("Try Again")) {
                        exportToFiles()
                    }
                )

            case .saveErrorGallery:
                return Alert(
                    title: Text("Error, failed to save in gallery"),
                    message: Text("Something went wrong or the server is not responding. Try again or do it later."),
                    primaryButton: .cancel(Text("Cancel")),
                    secondaryButton: .default(Text("Try Again")) {
                        saveToPhotos()
                    }
                )
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: - Header

    private var header: some View {
        ZStack {
            HStack(spacing: 12) {
                Button {
                    dismiss()
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.15))
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .frame(width: 32, height: 32)
                }

                Spacer()

                Menu {
                    Button {
                        saveToPhotos()
                    } label: {
                        Label("Save to gallery", systemImage: "square.and.arrow.down")
                    }

                    Button {
                        exportToFiles()
                    } label: {
                        Label("Save to files", systemImage: "folder")
                    }

                    Button(role: .destructive) {
                        activeAlert = .delete
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color("OnboardingYellow"))
                        Image(systemName: "ellipsis")
                            .rotationEffect(.degrees(90))
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.black)
                    }
                    .frame(width: 32, height: 32)
                }
            }

            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(1)
                .truncationMode(.tail)
                .allowsHitTesting(false)
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }

    // MARK: - Image

    private var contentImage: some View {
        Group {
            if let image = uiImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            } else if isLoadingImage {
                ProgressView()
                    .tint(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if loadingError != nil {
                ProgressView()
                    .tint(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                EmptyView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Prompt box

    private func promptBox(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(text)
                .font(.system(size: 15))
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)

            Spacer(minLength: 8)

            Button {
                UIPasteboard.general.string = text
                withAnimation(.easeInOut(duration: 0.2)) {
                    showCopyToast = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
                    withAnimation(.easeOut(duration: 0.2)) {
                        showCopyToast = false
                    }
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.12))
                    Image(systemName: "doc.on.doc.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color("OnboardingYellow"))
                }
                .frame(width: 32, height: 32)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white.opacity(0.08))
        )
    }

    // MARK: - Share button

    private var shareButton: some View {
        Button {
            isShareSheetPresented = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 17, weight: .semibold))
                Text("Share")
                    .font(.system(size: 17, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, minHeight: 56)
            .background(Color("OnboardingYellow"))
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
        .disabled(uiImage == nil && imageData == nil)
        .opacity((uiImage == nil && imageData == nil) ? 0.6 : 1.0)
    }

    // MARK: - Helpers

    @MainActor
    private func loadImageIfNeeded() async {
        isLoadingImage = true
        loadingError = nil
        uiImage = nil
        imageData = nil

        do {
            let (data, _) = try await URLSession.shared.data(from: imageURL)
            if let image = UIImage(data: data) {
                self.uiImage = image
                self.imageData = data
            } else {
                self.loadingError = "Failed to load image"
            }
        } catch {
            self.loadingError = "Failed to load image"
        }

        isLoadingImage = false
    }

    private func saveToPhotos() {
        guard let image = uiImage else { return }

        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized || status == .limited else {
                DispatchQueue.main.async {
                    activeAlert = .saveErrorGallery
                }
                return
            }

            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }) { success, _ in
                DispatchQueue.main.async {
                    if success {
                        activeAlert = .savedGallery
                    } else {
                        activeAlert = .saveErrorGallery
                    }
                }
            }
        }
    }

    private func exportToFiles() {
        guard let data = imageData else {
            activeAlert = .saveErrorFiles
            return
        }
        exportDocument = ImageDocument(data: data)
        isExportingToFiles = true
    }
}

// MARK: - FileDocument

struct ImageDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.jpeg] }

    var data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        guard let fileData = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.data = fileData
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

// MARK: - Share sheet

struct ImageShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
