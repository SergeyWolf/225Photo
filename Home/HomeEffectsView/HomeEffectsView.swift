//
//  HomeEffectsView.swift
//  225 Photo
//
//  Created by Сергей on 26.11.2025.
//

import SwiftUI

@available(iOS 17.0, *)
struct HomeEffectsView: View {
    @EnvironmentObject var appState: AppState
    @State private var templatesResponse: TemplatesResponse?
    @State private var isLoading = false
    @State private var loadError: String?
    @State private var didLoadFromApi = false
    @State private var showRateBanner = false
    @State private var userStat: ApidogStat?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                HomeNavBar()

                content
            }

            // Баннер оценки приложения
            if showRateBanner {
                RateAppBannerView(
                    onDismiss: {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            showRateBanner = false
                        }
                    }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            if Defaults.shouldShowRateBannerOnNextHome {
                withAnimation(.easeInOut(duration: 0.25)) {
                    showRateBanner = true
                }
                Defaults.shouldShowRateBannerOnNextHome = false
            }

            if let cached = appState.templatesResponse {
                templatesResponse = cached
                isLoading = false
                loadError = nil
            }

            guard !didLoadFromApi else { return }
            didLoadFromApi = true

            Task {
                await loadData()
            }
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if isLoading && templatesResponse == nil {
            VStack {
                Spacer()
                ProgressView()
                    .tint(Color("OnboardingYellow"))
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let error = loadError, templatesResponse == nil {
            VStack(spacing: 12) {
                Spacer()
                Text("Failed to load effects")
                    .foregroundColor(.white)
                Text(error)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.7))

                Button {
                    Task {
                        await loadData()
                    }
                } label: {
                    Text("Retry")
                        .font(.system(size: 15, weight: .semibold))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color("OnboardingYellow"))
                        .foregroundColor(.black)
                        .cornerRadius(20)
                }
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 24)
        } else if let response = templatesResponse {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    ForEach(response.categories) { category in
                        HomeCategoryRow(
                            allCategories: response.categories,
                            category: category
                        )
                    }

                    Spacer(minLength: 24)
                }
                .padding(.top, 8)
            }
        } else {
            EmptyView()
        }
    }

    // MARK: - API

    private func loadData() async {
        await MainActor.run {
            isLoading = true
            loadError = nil
        }

        // 1. /user/login
        let loginModel = ApidogLoginModel(
            gender: "m",
            isFb: nil,
            payments: "1",
            source: AppConstants.Bundle.bundle,
            userId: Defaults.userId
        )

        do {
            let loginResponse = try await ApidogService.shared.login(model: loginModel)

            await MainActor.run {
                let stat = loginResponse.data?.stat
                userStat = stat
                appState.userStat = stat

                if let stat = stat {
                    if let available = stat.availableGenerations {
                        appState.tokensBalance = available
                    }

                    print("Login OK. availableGenerations = \(stat.availableGenerations ?? 0)")
                } else {
                    print("Login OK, but no stat. message = \(loginResponse.message ?? "nil")")
                }
            }
        } catch {
            print("Apidog login failed: \(error)")
        }

        // 2. /effects/list
        let listModel = ApidogEffectsListModel(
            lang: "en",
            reels: "1",
            source: AppConstants.Bundle.bundle,
            userId: Defaults.userId
        )

        do {
            let response = try await ApidogService.shared.fetchEffectsList(model: listModel)

            await MainActor.run {
                self.templatesResponse = response
                self.isLoading = false
                appState.templatesResponse = response
                prefetchEffectImages(from: response)
            }
        } catch {
            await MainActor.run {
                self.loadError = error.localizedDescription
                self.isLoading = false
            }
        }
    }

    // MARK: - Prefetch effect images

    /// Собираем все preview URL эффектов и отдаём в ImageLoader.prefetch,
    /// чтобы картинки начали грузиться фоном, независимо от того, видны ли карточки.
    private func prefetchEffectImages(from response: TemplatesResponse) {
        let urls: [URL] = response.categories
            .flatMap { $0.effects }
            .compactMap { effect in
                let candidates = [
                    effect.previewBefore,
                    effect.previewProduction,
                    effect.preview
                ]
                return candidates
                    .compactMap { $0 }
                    .compactMap { URL(string: $0) }
                    .first
            }

        ImageLoader.shared.prefetch(urls: urls)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        if #available(iOS 17.0, *) {
            HomeEffectsView()
                .environmentObject(AppState())
                .preferredColorScheme(.dark)
        } else { }
    }
}

