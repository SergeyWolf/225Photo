//
//  EffectDetailView.swift
//  225 Photo
//
//  Created by Sergey on 27.11.2025.
//

import SwiftUI
import UIKit
import Photos
import AVFoundation

// MARK: - Детальный экран эффекта

@available(iOS 17.0, *)
struct EffectDetailView: View {
    let effect: TemplateEffect
    let allEffects: [TemplateEffect]

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState

    // ID выбранного эффекта в карусели
    @State private var selectedEffectId: Int

    // Bottom sheet "Select action"
    @State private var showSelectPhotoSheet = false

    // Bottom sheet "Photo requirements"
    @State private var showPhotoRequirements = false
    @State private var pendingPhotoSource: PhotoSource? = nil
    @State private var hasSeenPhotoRequirements = Defaults.hasSeenPhotoRequirements

    // Системный нативный пикер (камера / галерея)
    @State private var showSystemImagePicker = false
    @State private var pickerSourceType: UIImagePickerController.SourceType = .camera
    @State private var pickedImage: UIImage? = nil   // сюда прилетит выбранное фото

    // Экран загрузки генерации
    @State private var showGenerationLoading = false

    /// Пользователь закрыл экран загрузки → результат этой конкретной попытки не должен
    /// заново открывать GenerationLoadingView и показывать алерты.
    @State private var isGenerationCancelled = false

    // Ошибка генерации (для алерта на экране загрузки)
    @State private var showGenerationErrorAlert = false
    @State private var generationErrorMessage: String =
        "Something went wrong or the server is not responding. Try again or do it later."
    @State private var lastGeneratedImage: UIImage?

    // Результат генерации
    @State private var generationResultURL: URL?
    @State private var showGenerationResult = false

    // jobId последней генерации (для связи с History)
    @State private var lastJobId: String?

    // Paywall для премиум-функций
    @State private var showPaywall = false

    init(effect: TemplateEffect, allEffects: [TemplateEffect] = []) {
        self.effect = effect

        if allEffects.isEmpty {
            self.allEffects = [effect]
        } else {
            self.allEffects = allEffects
        }

        _selectedEffectId = State(initialValue: effect.id)
    }

    // MARK: - Вспомогательные свойства

    private var selectedEffect: TemplateEffect {
        allEffects.first(where: { $0.id == selectedEffectId }) ?? effect
    }

    /// Сколько раз повторяем массив эффектов для "почти бесконечной" карусели
    private let carouselRepeatCount = 10

    /// Массив для карусели: несколько копий allEffects подряд
    private var carouselItems: [TemplateEffect] {
        guard !allEffects.isEmpty else { return [] }
        return (0..<carouselRepeatCount).flatMap { _ in allEffects }
    }

    // MARK: - UI

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                PrimaryNavigationBar(
                    title: nil,
                    onBack: { dismiss() },
                    onCrownTap: {
                        showPaywall = true
                    }
                )

                // Без вертикального скролла — просто контент по макету
                VStack(spacing: 0) {
                    let imageURL = mainPreviewURL(for: selectedEffect)
                    let imageId = imageURL?.absoluteString ?? "effect_\(selectedEffect.id)"

                    let cardWidth  = UIScreen.main.bounds.width - 48  // 24 слева + 24 справа

                    // Ограничиваем высоту карточки: не более 55% экрана
                    let screenHeight = UIScreen.main.bounds.height
                    let naturalCardHeight = cardWidth * 3 / 2         // исходная пропорция 2:3
                    let maxCardHeight = screenHeight * 0.55
                    let cardHeight = min(naturalCardHeight, maxCardHeight)

                    CachedAsyncImage(
                        url: imageURL,
                        cornerRadius: 24,
                        contentMode: .fill
                    ) {
                        ZStack {
                            Rectangle()
                                .fill(Color.white.opacity(0.06))

                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.white)
                        }
                    }
                    .frame(width: cardWidth, height: cardHeight)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .id(imageId)

                    if !carouselItems.isEmpty {
                        VStack(alignment: .center, spacing: 12) {
                            ScrollViewReader { proxy in
                                ScrollView(.horizontal, showsIndicators: false) {
                                    LazyHStack(spacing: 16) {
                                        ForEach(carouselItems.indices, id: \.self) { index in
                                            let item = carouselItems[index]

                                            VStack(spacing: 6) {
                                                ZStack {
                                                    Circle()
                                                        .fill(Color.white.opacity(0.06))

                                                    Circle()
                                                        .stroke(
                                                            selectedEffectId == item.id
                                                            ? Color("OnboardingYellow")
                                                            : Color.clear,
                                                            lineWidth: 2
                                                        )

                                                    CachedAsyncImage(
                                                        url: thumbnailPreviewURL(for: item),
                                                        cornerRadius: 36,
                                                        contentMode: .fill
                                                    ) {
                                                        ProgressView()
                                                            .progressViewStyle(.circular)
                                                    }
                                                    .clipShape(Circle())
                                                    .padding(3)
                                                }
                                                .frame(width: 72, height: 72)

                                                Text(item.title)
                                                    .font(.system(
                                                        size: 12,
                                                        weight: selectedEffectId == item.id ? .semibold : .regular
                                                    ))
                                                    .foregroundColor(
                                                        selectedEffectId == item.id
                                                        ? .white
                                                        : .white.opacity(0.7)
                                                    )
                                                    .lineLimit(1)
                                            }
                                            .onTapGesture {
                                                withAnimation(.easeInOut(duration: 0.2)) {
                                                    selectedEffectId = item.id
                                                }
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.top, 3)
                                }
                                .onAppear {
                                    guard !carouselItems.isEmpty, !allEffects.isEmpty else { return }

                                    // Скроллим к середине, чтобы было ощущение бесконечной карусели
                                    let base = (carouselItems.count / 2) / allEffects.count * allEffects.count
                                    let initialIndex = allEffects.firstIndex(where: { $0.id == selectedEffectId }) ?? 0
                                    let target = base + initialIndex

                                    DispatchQueue.main.async {
                                        proxy.scrollTo(target, anchor: .center)
                                    }
                                }
                            }
                        }
                    }

                    Button {
                        if appState.hasActiveSubscription {
                            // 1) нет подписки → экран подписки
                            if !appState.hasActiveSubscription {
                                showPaywall = true
                                return
                            }

                            // 2) подписка есть, но токенов < минимального порога → экран токенов
                            if appState.tokensBalance < AppConstants.MinCounToken.token {
                                // при активной подписке fullScreenCover покажет TokensPaywallView
                                showPaywall = true
                                return
                            }

                            // 3) подписка есть и токенов ≥ порога → можно идти выбирать фото
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showSelectPhotoSheet = true
                            }
                        } else {
                            showPaywall = true
                        }
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 17, weight: .semibold))
                            Text("Add Photo")
                                .font(.system(size: 17, weight: .semibold))
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(Color("OnboardingYellow"))
                        .cornerRadius(16)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)

                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showPhotoRequirements = true
                            pendingPhotoSource = nil
                        }
                    } label: {
                        Text("Photo requirements")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white.opacity(0.7))
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 5)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
        }
        .sheet(isPresented: $showSelectPhotoSheet) {
            SelectPhotoActionSheet(
                onTakePhoto: {
                    handlePhotoAction(source: .camera)
                },
                onChooseFromGallery: {
                    handlePhotoAction(source: .library)
                },
                onCancel: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showSelectPhotoSheet = false
                    }
                }
            )
            .presentationDetents([.height(260)])
            .presentationDragIndicator(.visible)
            .background(Color.black.opacity(0.7))
            .presentationBackground(.clear)
        }
        .sheet(isPresented: $showPhotoRequirements) {
            PhotoRequirementsSheet(
                onOkay: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showPhotoRequirements = false
                        Defaults.hasSeenPhotoRequirements = true
                        hasSeenPhotoRequirements = true

                        if let source = pendingPhotoSource {
                            startPhotoFlow(for: source)
                            pendingPhotoSource = nil
                        }
                    }
                }
            )
            .presentationDetents([.height(520)])
            .presentationDragIndicator(.visible)
        }
        .fullScreenCover(isPresented: $showSystemImagePicker) {
            ImagePicker(
                sourceType: pickerSourceType,
                selectedImage: $pickedImage
            )
            .ignoresSafeArea()
        }
        .fullScreenCover(isPresented: $showGenerationLoading) {
            GenerationLoadingView(
                errorMessage: generationErrorMessage,
                isShowingErrorAlert: $showGenerationErrorAlert,
                onCancel: {
                    isGenerationCancelled = true
                    showGenerationErrorAlert = false
                    showGenerationLoading = false
                },
                onRetry: {
                    isGenerationCancelled = false
                    showGenerationErrorAlert = false
                    if let image = lastGeneratedImage {
                        startGeneration(with: image)
                    }
                }
            )
        }
        .fullScreenCover(isPresented: $showPaywall) {
            if appState.hasActiveSubscription {
                TokensPaywallView()
                    .environmentObject(appState)
            } else {
                SubscriptionPaywallView()
                    .environmentObject(appState)
            }
        }
        .onChange(of: pickedImage) { _, newImage in
            guard let image = newImage else { return }
            startGeneration(with: image)
        }
        .background(
            NavigationLink(
                destination: generationResultDestination,
                isActive: $showGenerationResult,
                label: { EmptyView() }
            )
            .hidden()
        )
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)   // скрываем MainTabView на детальной карточке
    }

    // MARK: - Destination

    @ViewBuilder
    private var generationResultDestination: some View {
        if let url = generationResultURL {
            GenerationResultView(
                imageURL: url,
                title: selectedEffect.title,
                prompt: nil,
                onDelete: { }
            )
        } else {
            EmptyView()
        }
    }

    // MARK: - Фото и генерация

    private func handlePhotoAction(source: PhotoSource) {
        showSelectPhotoSheet = false

        if hasSeenPhotoRequirements {
            startPhotoFlow(for: source)
        } else {
            pendingPhotoSource = source
            showPhotoRequirements = true
        }
    }

    private func startPhotoFlow(for source: PhotoSource) {
        switch source {
        case .camera:
            guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
                return
            }
            pickerSourceType = .camera
            requestCameraAccessAndPresentPicker()          // 👈 запрашиваем доступ к камере

        case .library:
            guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary) else {
                return
            }
            pickerSourceType = .photoLibrary
            requestPhotoLibraryAccessAndPresentPicker()    // 👈 запрос к фотогалерее
        }
    }

    /// Запрос доступа к камере и показ пикера после разрешения
    private func requestCameraAccessAndPresentPicker() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)

        switch status {
        case .authorized:
            showSystemImagePicker = true

        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        self.showSystemImagePicker = true
                    } else {
                        // доступ не дали — здесь можно добавить алерт, если нужно
                    }
                }
            }

        case .denied, .restricted:
            // пользователь уже запретил доступ — при желании можно открыть настройки
            break

        @unknown default:
            break
        }
    }

    /// Запрос доступа к фотогалерее и показ пикера после разрешения
    private func requestPhotoLibraryAccessAndPresentPicker() {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)

        switch status {
        case .authorized, .limited:
            showSystemImagePicker = true

        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { newStatus in
                DispatchQueue.main.async {
                    if newStatus == .authorized || newStatus == .limited {
                        self.showSystemImagePicker = true
                    } else {
                        // доступ не дали — можно добавить алерт
                    }
                }
            }

        case .denied, .restricted:
            break

        @unknown default:
            break
        }
    }

    private func startGeneration(with image: UIImage) {
        lastGeneratedImage = image
        isGenerationCancelled = false
        showGenerationErrorAlert = false
        showGenerationLoading = true

        Task {
            do {
                let result = try await GenerationManager.shared.generateWithPhoto(
                    image: image,
                    effect: selectedEffect,
                    appState: appState
                )

                await MainActor.run {
                    guard !isGenerationCancelled else { return }

                    showGenerationLoading = false

                    if let url = result.imageURL {
                        generationResultURL = url
                        showGenerationResult = true
                        lastJobId = result.jobId
                    } else {
                        generationErrorMessage = "Generation finished but result URL is missing."
                        showGenerationErrorAlert = true
                        showGenerationLoading = true
                    }
                }
            } catch {
                await MainActor.run {
                    guard !isGenerationCancelled else { return }

                    generationErrorMessage = error.localizedDescription.isEmpty
                    ? "Something went wrong or the server is not responding. Try again or do it later."
                    : error.localizedDescription

                    showGenerationErrorAlert = true
                }
            }
        }
    }

    // MARK: - URL helpers

    private func mainPreviewURL(for effect: TemplateEffect) -> URL? {
        let urlString = effect.previewProduction ?? effect.preview
        guard let urlString, let url = URL(string: urlString) else { return nil }
        return url
    }

    private func thumbnailPreviewURL(for effect: TemplateEffect) -> URL? {
        let urlString = effect.previewBefore ?? effect.previewProduction ?? effect.preview
        guard let urlString, let url = URL(string: urlString) else { return nil }
        return url
    }

    // MARK: - Тип источника фото

    enum PhotoSource {
        case camera
        case library
    }
}

