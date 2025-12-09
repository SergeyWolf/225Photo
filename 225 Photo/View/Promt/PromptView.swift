//
//  PromptView.swift
//  225 Photo
//
//  Created by Sergey on 01.12.2025.
//

import SwiftUI
import UIKit

@available(iOS 17.0, *)
struct PromptView: View {
    @EnvironmentObject var appState: AppState

    @State private var promptText: String = ""
    @State private var clipboardText: String = ""
    @State private var selectedStyleId: Int = 0
    @State private var showCopyToast: Bool = false
    @State private var isStylesSheetPresented: Bool = false
    @State private var showGenerationLoading: Bool = false
    @State private var isGenerationCancelled: Bool = false
    @State private var showGenerationErrorAlert: Bool = false
    @State private var generationErrorMessage: String =
        "Something went wrong or the server is not responding. Try again or do it later."
    @State private var generationResultURL: URL?
    @State private var generationResultTitle: String = ""
    @State private var showGenerationResult: Bool = false

    @State private var showPaywall = false
    @State private var lastPrompt: String = ""
    @State private var lastStyleId: Int? = nil

    @FocusState private var isPromptFocused: Bool

    private let maxCharacters: Int = 300
    private let promptBoxHeight: CGFloat = 190

    // MARK: - Styles data

    /// Все включённые эффекты из templatesResponse (для sheet'а)
    private var allEnabledEffects: [TemplateEffect] {
        guard let response = appState.templatesResponse else {
            return []
        }

        // Собираем все эффекты из всех категорий
        let allEffects = response.categories.flatMap { $0.effects }

        // Фильтруем только включённые и убираем дубликаты по id
        var seen = Set<Int>()
        var unique: [TemplateEffect] = []

        for effect in allEffects where effect.isEnabled {
            if !seen.contains(effect.id) {
                seen.insert(effect.id)
                unique.append(effect)
            }
        }

        return unique
    }

    /// Стили, которые показываем в горизонтальном списке (ограниченный набор)
    private var effectsStyles: [TemplateEffect] {
        Array(allEnabledEffects.prefix(10))
    }

    private var trimmedPrompt: String {
        promptText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isGenerateEnabled: Bool {
        !trimmedPrompt.isEmpty
    }

    private var canPaste: Bool {
        !clipboardText.isEmpty
    }

    private var selectedStyle: TemplateEffect? {
        guard selectedStyleId != 0 else { return nil }
        return allEnabledEffects.first(where: { $0.id == selectedStyleId })
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black
                .ignoresSafeArea()
                .onTapGesture {
                    isPromptFocused = false
                }

            VStack(alignment: .leading, spacing: 16) {
                header

                promptInput

                stylesSection

                Spacer()

                generateButton
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .onAppear {
                refreshClipboard()
            }

            if showCopyToast {
                Text("Text copied")
                    .font(.system(size: 13, weight: .medium))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(0.85))
                    .foregroundColor(.white)
                    .cornerRadius(16)
                    .padding(.top, 110)
                    .padding(.trailing, 24)
                    .transition(.opacity
                        .combined(with: .move(edge: .top)))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            withAnimation(.easeOut(duration: 0.2)) {
                                showCopyToast = false
                            }
                        }
                    }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIPasteboard.changedNotification)) { _ in
            refreshClipboard()
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

                    guard !lastPrompt.isEmpty else { return }
                    let style = lastStyleId.flatMap { id in
                        allEnabledEffects.first(where: { $0.id == id })
                    }
                    runPromptGeneration(prompt: lastPrompt, styleEffect: style)
                }
            )
        }
        .sheet(isPresented: $isStylesSheetPresented) {
            PromptStylesSheetView(
                effects: allEnabledEffects,
                selectedStyleId: $selectedStyleId
            )
            .presentationDetents([.fraction(0.7), .large])
            .presentationDragIndicator(.hidden)
            .presentationCornerRadius(24)
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
        .background(
            NavigationLink(
                destination: generationResultDestination,
                isActive: $showGenerationResult,
                label: { EmptyView() }
            )
            .hidden()
        )
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            MainTabHeader(title: "Promt") {
                showPaywall = true
            }
        }
    }

    // MARK: - Prompt input

    @available(iOS 17.0, *)
    private var promptInput: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(
                    isPromptFocused ? Color("OnboardingYellow") : Color.white.opacity(0.18),
                    lineWidth: isPromptFocused ? 2 : 1
                )
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.white.opacity(0.06))
                )
                .frame(height: promptBoxHeight)

            VStack(spacing: 0) {
                TextEditor(text: $promptText)
                    .font(.system(size: 15))
                    .foregroundColor(.white)
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, 12)
                    .padding(.top, 10)
                    .padding(.bottom, 8)
                    .frame(height: promptBoxHeight - 42)
                    .focused($isPromptFocused)
                    .onChange(of: promptText) { _, newValue in
                        if newValue.count > maxCharacters {
                            promptText = String(newValue.prefix(maxCharacters))
                        }
                    }
                    .overlay(alignment: .topLeading) {
                        if trimmedPrompt.isEmpty {
                            Text("Describe in detail what the photo will show…")
                                .foregroundColor(.white.opacity(0.4))
                                .font(.system(size: 15))
                                .padding(.horizontal, 16)
                                .padding(.top, 14)
                        }
                    }

                HStack {
                    Text("\(promptText.count)/\(maxCharacters)")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.6))

                    Spacer()

                    HStack(spacing: 12) {
                        Button(action: pasteFromClipboard) {
                            Text("Past")
                                .font(.system(size: 13, weight: .medium))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(Color.white.opacity(canPaste ? 0.14 : 0.08))
                                )
                                .foregroundColor(canPaste ? .white : .white.opacity(0.4))
                        }
                        .disabled(!canPaste)

                        Button(action: copyToClipboard) {
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 14, weight: .medium))
                                .frame(width: 30, height: 30)
                                .background(
                                    Capsule()
                                        .fill(Color.white.opacity(
                                            trimmedPrompt.isEmpty ? 0.08 : 0.14
                                        ))
                                )
                                .foregroundColor(
                                    trimmedPrompt.isEmpty ? .white.opacity(0.4) : .white
                                )
                        }
                        .disabled(trimmedPrompt.isEmpty)

                        Button(action: clearPrompt) {
                            Image(systemName: "trash")
                                .font(.system(size: 14, weight: .medium))
                                .frame(width: 30, height: 30)
                                .background(
                                    Capsule()
                                        .fill(Color.white.opacity(
                                            trimmedPrompt.isEmpty ? 0.08 : 0.14
                                        ))
                                )
                                .foregroundColor(
                                    trimmedPrompt.isEmpty ? .white.opacity(0.4) : .white
                                )
                        }
                        .disabled(trimmedPrompt.isEmpty)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 10)
            }
        }
        .onTapGesture {
            isPromptFocused = true
        }
    }

    // MARK: - Styles section

    private var stylesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Styles")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)

                Spacer()

                Button {
                    if !allEnabledEffects.isEmpty {
                        isStylesSheetPresented = true
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text("See all")
                            .font(.system(size: 13, weight: .medium))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .semibold))
                    }
                }
                .foregroundColor(allEnabledEffects.isEmpty ? .white.opacity(0.3) : .white)
                .disabled(allEnabledEffects.isEmpty)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    NoStyleChip(isSelected: selectedStyleId == 0)
                        .onTapGesture {
                            selectedStyleId = 0
                        }

                    ForEach(effectsStyles) { effect in
                        PromptStyleChip(
                            effect: effect,
                            isSelected: effect.id == selectedStyleId
                        )
                        .onTapGesture {
                            selectedStyleId = effect.id
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    // MARK: - Generate button

    private var generateButton: some View {
        Button(action: generate) {
            Text("Generate")
                .font(.system(size: 17, weight: .semibold))
                .frame(maxWidth: .infinity, minHeight: 54)
        }
        .buttonStyle(.plain)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(isGenerateEnabled ? Color("OnboardingYellow") : Color.white.opacity(0.14))
        )
        .foregroundColor(isGenerateEnabled ? .black : .white.opacity(0.7))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: isGenerateEnabled ? 0 : 1)
        )
        .padding(.bottom, 4)
        .disabled(!isGenerateEnabled)
    }

    // MARK: - Actions

    private func refreshClipboard() {
        clipboardText = UIPasteboard.general.string ?? ""
    }

    private func pasteFromClipboard() {
        let value = UIPasteboard.general.string ?? ""
        guard !value.isEmpty else { return }

        if promptText.isEmpty {
            promptText = value
        } else {
            promptText += (promptText.hasSuffix(" ") ? "" : " ") + value
        }
    }

    private func copyToClipboard() {
        guard !trimmedPrompt.isEmpty else { return }
        UIPasteboard.general.string = trimmedPrompt

        withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
            showCopyToast = true
        }
    }

    private func clearPrompt() {
        promptText = ""
    }

    private func generate() {
        guard isGenerateEnabled else { return }

        // Если нет активной подписки — показываем paywall вместо генерации
        if !appState.hasActiveSubscription {
            isPromptFocused = false
            showPaywall = true
            return
        }
        
        // 2) подписка есть, но токенов < 2 → экран токенов
        if appState.tokensBalance < AppConstants.MinCounToken.token {
            showPaywall = true    // здесь откроется TokensPaywallView
            return
        }

        isPromptFocused = false
        lastPrompt = trimmedPrompt
        lastStyleId = (selectedStyleId == 0) ? nil : selectedStyleId
        isGenerationCancelled = false
        showGenerationErrorAlert = false
        showGenerationLoading = true

        let style = selectedStyleId == 0
        ? nil
        : allEnabledEffects.first(where: { $0.id == selectedStyleId })

        runPromptGeneration(prompt: lastPrompt, styleEffect: style)
    }

    // MARK: - Текстовая генерация через GenerationManager

    private func runPromptGeneration(prompt: String, styleEffect: TemplateEffect?) {
        Task {
            do {
                let result = try await GenerationManager.shared.generateWithPrompt(
                    prompt: prompt,
                    styleEffect: styleEffect,
                    appState: appState
                )

                await MainActor.run {
                    guard !isGenerationCancelled else { return }

                    showGenerationLoading = false

                    if let url = result.imageURL {
                        generationResultURL = url
                        generationResultTitle = styleEffect?.title ?? "Prompt"
                        showGenerationResult = true
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

    // MARK: - Destination

    @ViewBuilder
    private var generationResultDestination: some View {
        if let url = generationResultURL {
            GenerationResultView(
                imageURL: url,
                title: generationResultTitle,
                prompt: lastPrompt,
                onDelete: {}
            )
        } else {
            EmptyView()
        }
    }
}

// MARK: - Subviews (chips)

struct NoStyleChip: View {
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .strokeBorder(
                        isSelected ? Color("OnboardingYellow") : Color.white.opacity(0.25),
                        lineWidth: 2
                    )
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.06))
                    )

                Circle()
                    .fill(Color("OnboardingYellow"))
                    .frame(width: 28, height: 28)

                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.black)
            }
            .frame(width: 70, height: 70)

            Text("No Style")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(
                    isSelected ? Color("OnboardingYellow") : .white.opacity(0.7)
                )
        }
    }
}

struct PromptStyleChip: View {
    let effect: TemplateEffect
    let isSelected: Bool

    private var previewURL: URL? {
        let urlString = effect.previewProduction ?? effect.preview ?? effect.previewBefore
        return urlString.flatMap { URL(string: $0) }
    }

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.07))

                Circle()
                    .stroke(
                        isSelected ? Color("OnboardingYellow") : Color.clear,
                        lineWidth: 2
                    )

                if let url = previewURL {
                    CachedAsyncImage(
                        url: url,
                        cornerRadius: 36,
                        contentMode: .fill
                    ) {
                        ProgressView()
                            .progressViewStyle(.circular)
                    }
                    .clipShape(Circle())
                } else {
                    Image(systemName: "photo")
                        .resizable()
                        .scaledToFit()
                        .padding(16)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .frame(width: 70, height: 70)

            Text(effect.title)
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(isSelected ? .white : .white.opacity(0.7))
                .lineLimit(1)
        }
    }
}
