//
//  TokensPaywallView.swift
//  225 Photo
//
//  Created by Сергей on 08.12.2025.
//

import SwiftUI
import ApphudSDK
import StoreKit

// MARK: - Модель пакета токенов

struct TokenPack: Identifiable {
    let id: String
    let tokens: Int
    let priceText: String
    let badgeText: String?
    let product: ApphudProduct?
}

// MARK: - Tokens paywall — фуллскрин

struct TokensPaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @EnvironmentObject var appState: AppState

    @State private var isLoading: Bool = true
    @State private var errorMessage: String?
    @State private var packs: [TokenPack] = []

    /// Можно показать крестик и свайп-дизмисс только после 3 секунд
    @State private var canClose: Bool = false

    /// placement для токенов в Apphud (поменяй при необходимости)
    private let tokensPlacementId = "tokens"

    var body: some View {
        GeometryReader { geo in
            let safeTop = geo.safeAreaInsets.top
            let safeBottom = geo.safeAreaInsets.bottom
            let heroHeight = geo.size.height * 0.45

            ZStack(alignment: .topTrailing) {
                Color.black.ignoresSafeArea()

                VStack(spacing: 0) {
                    Spacer(minLength: safeTop)

                    ZStack(alignment: .bottom) {
                        Image("paywall_hero")
                            .resizable()
                            .scaledToFill()
                            .frame(width: geo.size.width,
                                   height: heroHeight)
                            .clipped()

                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.black.opacity(0.0),
                                Color.black.opacity(0.85),
                                Color.black
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: heroHeight * 0.55)
                        .allowsHitTesting(false)
                    }

                    VStack(spacing: 16) {
                        VStack(spacing: 6) {
                            Text("Need more generations?")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(.white)

                            Text("Buy additional tokens")
                                .font(.system(size: 15))
                                .foregroundColor(.white.opacity(0.7))

                            HStack(spacing: 4) {
                                Text("My tokens:")
                                    .font(.system(size: 15))
                                    .foregroundColor(.white.opacity(0.7))

                                Text("\(appState.tokensBalance)")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(Color("OnboardingYellow"))
                            }
                            .padding(.top, 2)
                        }
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)

                        if isLoading {
                            ProgressView()
                                .tint(.white)
                                .padding(.top, 8)
                        } else if let errorMessage {
                            Text(errorMessage)
                                .font(.system(size: 13))
                                .foregroundColor(.red.opacity(0.9))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 8)
                        }

                        VStack(spacing: 12) {
                            ForEach(packs) { pack in
                                TokenPackRow(pack: pack) {
                                    handlePurchase(pack: pack)
                                }
                            }
                        }
                        .padding(.top, 4)

                        Spacer(minLength: 8)

                        HStack {
                            Button("Privacy Policy") {
                                openURL(AppConstants.Legal.privacyPolicyURL)
                            }

                            Spacer()

                            Button("Terms of Use") {
                                openURL(AppConstants.Legal.termsOfUseURL)
                            }
                        }
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.bottom, max(safeBottom, 14))
                    }
                    .padding(.horizontal, 20)
                }

                if canClose {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(10)
                    }
                    .padding(.top, safeTop + 40)
                    .padding(.trailing, 16)
                    .transition(.opacity)
                }
            }
        }
        .ignoresSafeArea(edges: .top)
        .interactiveDismissDisabled(!canClose)
        .onAppear {
            loadTokenPacks()

            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation(.easeInOut) {
                    canClose = true
                }
            }
        }
        .onDisappear {
            refreshTokensFromServer()
        }
    }
    
    /// После закрытия экрана токенов подтягиваем актуальное количество токенов с сервера.
    private func refreshTokensFromServer() {
        let loginModel = ApidogLoginModel(
            gender: "m",
            isFb: nil,
            payments: "1",
            source: AppConstants.Bundle.bundle,
            userId: Defaults.userId
        )

        Task {
            do {
                let loginResponse = try await ApidogService.shared.login(model: loginModel)
                let stat = loginResponse.data?.stat

                await MainActor.run {
                    appState.userStat = stat
                    if let available = stat?.availableGenerations {
                        appState.tokensBalance = available
                    }
                }
            } catch {
                print("Apidog login (refresh tokens after TokensPaywall) failed: \(error)")
            }
        }
    }

    // MARK: - Загрузка продуктов из Apphud

    private func loadTokenPacks() {
        isLoading = true
        errorMessage = nil

        Apphud.fetchPlacements { placements, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                    return
                }

                guard !placements.isEmpty else {
                    self.isLoading = false
                    self.errorMessage = "No placements configured."
                    return
                }

                let placement =
                    placements.first(where: { $0.identifier == tokensPlacementId }) ??
                    placements[0]

                guard let paywall = placement.paywall else {
                    self.isLoading = false
                    self.errorMessage = "Placement has no paywall."
                    return
                }

                let products = paywall.products
                guard !products.isEmpty else {
                    self.isLoading = false
                    self.errorMessage = "No products in tokens paywall."
                    return
                }

                self.packs = products.map { mapProductToTokenPack($0) }
                self.isLoading = false
            }
        }
    }

    private func mapProductToTokenPack(_ product: ApphudProduct) -> TokenPack {
        let productId = product.productId
        let sk = product.skProduct

        let tokensCount: Int = {
            if let first = productId.split(separator: "_").first,
               let value = Int(first) {
                return value
            }
            return 100
        }()

        var priceText = ""
        if let sk {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.locale = sk.priceLocale
            priceText = formatter.string(from: sk.price) ?? ""
        }

        let badge: String?
        if productId.contains("500") || productId.contains("1000") || productId.contains("2000") {
            badge = "SAVE 40%"
        } else {
            badge = nil
        }

        return TokenPack(
            id: productId,
            tokens: tokensCount,
            priceText: priceText,
            badgeText: badge,
            product: product
        )
    }

    // MARK: - Покупка токенов

    private func handlePurchase(pack: TokenPack) {
        guard let product = pack.product else { return }

        Apphud.purchase(product) { result in
            DispatchQueue.main.async {
                if let error = result.error { return }

                if let purchase = result.nonRenewingPurchase, purchase.isActive() {
                    appState.tokensBalance += pack.tokens
                    Defaults.tokensBalance = appState.tokensBalance

                    dismiss()
                } else {
                    print("ℹ️ Tokens purchase completed but not active state")
                }
            }
        }
    }
}
