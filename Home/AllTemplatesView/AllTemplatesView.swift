//
//  AllTemplatesView.swift
//  225 Photo
//
//  Created by Сергей on 27.11.2025.
//

import SwiftUI

@available(iOS 17.0, *)
struct AllTemplatesView: View {
    let categories: [TemplateCategory]
    let initialCategory: TemplateCategory

    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCategoryId: Int

    @State private var showSubscriptionPaywall = false
    @State private var showTokensPaywall = false

    init(categories: [TemplateCategory], initialCategory: TemplateCategory) {
        self.categories = categories
        self.initialCategory = initialCategory
        _selectedCategoryId = State(initialValue: initialCategory.id)
    }

    private var selectedCategory: TemplateCategory? {
        categories.first(where: { $0.id == selectedCategoryId }) ?? categories.first
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                PrimaryNavigationBar(
                    title: "All templates",
                    onBack: { dismiss() },
                    onCrownTap: {
                        // если есть подписка — открываем TokensPaywall,
                        // иначе обычный SubscriptionPaywall
                        if appState.hasActiveSubscription {
                            showTokensPaywall = true
                        } else {
                            showSubscriptionPaywall = true
                        }
                    }
                )

                categoryTabs

                ScrollView(.vertical, showsIndicators: false) {
                    let columns = [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12)
                    ]

                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(selectedCategory?.effects ?? []) { effect in
                            NavigationLink {
                                EffectDetailView(
                                    effect: effect,
                                    allEffects: selectedCategory?.effects ?? []
                                )
                            } label: {
                                EffectCardView(effect: effect)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
        }
        .onAppear {
            prefetchEffectImages()
        }
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .fullScreenCover(isPresented: $showSubscriptionPaywall) {
            SubscriptionPaywallView()
                .environmentObject(appState)
        }
        .fullScreenCover(isPresented: $showTokensPaywall) {
            TokensPaywallView()
                .environmentObject(appState)
        }
    }

    // MARK: - Category tabs

    private var categoryTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 24) {
                ForEach(categories) { category in
                    Button {
                        selectedCategoryId = category.id
                    } label: {
                        VStack(spacing: 4) {
                            Text(category.title)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(
                                    selectedCategoryId == category.id
                                    ? Color("OnboardingYellow")
                                    : .white.opacity(0.6)
                                )

                            Rectangle()
                                .frame(height: 2)
                                .foregroundColor(
                                    selectedCategoryId == category.id
                                    ? Color("OnboardingYellow")
                                    : Color.white.opacity(0.2)
                                )
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.bottom, 8)
    }


    // MARK: - Prefetch

    /// Префетчим превью всех эффектов во всех категориях,
    /// чтобы грид открывался с уже подгруженными картинками.
    private func prefetchEffectImages() {
        let urls: [URL] = categories
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
