import SwiftUI
import StoreKit
import ApphudSDK

// MARK: - Paywall

struct SubscriptionPaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @EnvironmentObject var appState: AppState

    // выбранный план из Apphud
    @State private var selectedPlan: SubscriptionPlan? = nil

    // Apphud-планы, подтянутые с бэка
    @State private var apphudPlans: [SubscriptionPlan] = []
    @State private var isLoadingProducts: Bool = true
    @State private var paywallError: String?
    @State private var canClose: Bool = false

    // MARK: - Активные планы (только реальные из Apphud)

    private var activePlans: [SubscriptionPlan] {
        apphudPlans
    }
    
    var body: some View {
        GeometryReader { geo in
            let h = geo.size.height
            let safeTop = geo.safeAreaInsets.top
            let safeBottom = geo.safeAreaInsets.bottom

            let isSmall = h < 750
            let heroHeight      = isSmall ? h * 0.42 : h * 0.48
            let gradientHeight  = isSmall
                ? min(h * 0.22, 170.0)
                : min(h * 0.28, 200.0)

            let titleTopPadding : CGFloat = isSmall ? 10.0 : 16.0
            let titleBottomPad  : CGFloat = isSmall ? 16.0 : 24.0
            let plansBottomPad  : CGFloat = isSmall ? 12.0 : 16.0
            let cancelBottomPad : CGFloat = isSmall ? 16.0 : 20.0
            let buttonBottomPad : CGFloat = isSmall ? 12.0 : 16.0
            let linksBottomPad  = safeBottom + 24.0
            
            ZStack(alignment: .topTrailing) {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    Spacer(minLength: safeTop)

                    ZStack(alignment: .bottom) {
                        Image("paywall_hero")
                            .resizable()
                            .scaledToFill()
                            .frame(width: geo.size.width, height: heroHeight)
                            .clipped()
                        
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.black.opacity(0.0),
                                Color.black.opacity(0.75),
                                Color.black
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: gradientHeight)
                        .allowsHitTesting(false)
                    }
                    
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 0) {
                            VStack(spacing: 12) {
                                Text("A new level of generation")
                                    .font(.system(size: 24, weight: .semibold))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    bullet("Access to all effects")
                                    bullet("Unlimited generation")
                                    bullet("Access to all functions")
                                }
                                .frame(maxWidth: .infinity, alignment: .center)
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, titleTopPadding)
                            .padding(.bottom, titleBottomPad)

                            if isLoadingProducts {
                                ProgressView()
                                    .tint(.white)
                                    .padding(.bottom, 8)
                            } else if let error = paywallError {
                                Text(error)
                                    .font(.system(size: 13))
                                    .foregroundColor(.red.opacity(0.9))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 20)
                                    .padding(.bottom, 8)
                            }

                            // Планы подписки (только реальные из Apphud)
                            VStack(spacing: 10) {
                                ForEach(activePlans) { plan in
                                    SubscriptionPlanRow(
                                        plan: plan,
                                        isSelected: plan.id == selectedPlan?.id
                                    ) {
                                        selectedPlan = plan
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, plansBottomPad)
                            
                            HStack(spacing: 8) {
                                Image(systemName: "clock.arrow.circlepath")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.6))
                                
                                Text("Cancel Anytime")
                                    .font(.system(size: 13))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.bottom, cancelBottomPad)
                            
                            Button(action: handleContinue) {
                                Text("Continue")
                                    .font(.system(size: 17, weight: .semibold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Color("OnboardingYellow"))
                                    .cornerRadius(16)
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, buttonBottomPad)
                            .disabled(selectedPlan == nil || isLoadingProducts || paywallError != nil)
                            .opacity((selectedPlan == nil || isLoadingProducts || paywallError != nil) ? 0.6 : 1.0)
                            
                            HStack {
                                Button("Privacy Policy") {
                                    openURL(AppConstants.Legal.privacyPolicyURL)
                                }
                                .font(.system(size: 13))
                                
                                Spacer()
                                
                                Button("Restore Purchases") {
                                    restorePurchases()
                                }
                                .font(.system(size: 13, weight: .semibold))
                                
                                Spacer()
                                
                                Button("Terms of Use") {
                                    openURL(AppConstants.Legal.termsOfUseURL)
                                }
                                .font(.system(size: 13))
                            }
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.horizontal, 20)
                            .padding(.bottom, linksBottomPad)
                        }
                    }
                }
                
                if canClose {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.top, safeTop + 50)
                    .padding(.trailing, 16)
                    .transition(.opacity)
                }
            }
        }
        .ignoresSafeArea(edges: .top)
        .interactiveDismissDisabled(!canClose)
        .onAppear {
            setupApphudPaywall()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation(.easeInOut) {
                    canClose = true
                }
            }
        }
    }

    // MARK: - Bullet

    private func bullet(_ text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "sparkles")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white)
                .frame(width: 18, alignment: .leading)

            Text(text)
                .font(.system(size: 15))
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
        }
    }
    
    // MARK: - Apphud: загрузка paywall и продуктов
    private func setupApphudPaywall() {
        isLoadingProducts = true
        paywallError = nil

        let targetPlacementId = "main"

        Apphud.fetchPlacements { placements, error in
            DispatchQueue.main.async {
                // 1) Обрабатываем ошибку
                if let error = error {
                    self.isLoadingProducts = false
                    self.paywallError = error.localizedDescription
                    return
                }

                // 2) Проверяем, что массив не пустой
                guard !placements.isEmpty else {
                    self.isLoadingProducts = false
                    self.paywallError = "No placements configured in Apphud."
                    return
                }

                // 3) Ищем нужный placement по identifier, иначе берём первый
                let placement =
                    placements.first(where: { $0.identifier == targetPlacementId }) ??
                    placements[0]

                guard let paywall = placement.paywall else {
                    self.isLoadingProducts = false
                    self.paywallError = "Placement has no paywall."
                    return
                }

                let products = paywall.products
                guard !products.isEmpty else {
                    self.isLoadingProducts = false
                    self.paywallError = "No products in paywall \(paywall.identifier)."
                    return
                }

                // 4) Логируем показ paywall для Apphud-аналитики
                Apphud.paywallShown(paywall)

                // 5) Маппим в наши SubscriptionPlan + сортируем по длине периода:
                // Annual → Monthly → Weekly → Daily/остальные
                let plansWithWeight: [(SubscriptionPlan, Int)] = products.map { product in
                    let plan = mapProductToPlan(product)
                    let sk = product.skProduct

                    var weight = 50
                    if let s = sk?.subscriptionPeriod {
                        switch s.unit {
                        case .year:  weight = 0
                        case .month: weight = 1
                        case .week:  weight = 2
                        case .day:   weight = 3
                        @unknown default:
                            weight = 50
                        }
                    }

                    return (plan, weight)
                }

                let sortedPlans = plansWithWeight
                    .sorted { $0.1 < $1.1 }
                    .map { $0.0 }

                self.apphudPlans = sortedPlans

                if let first = sortedPlans.first {
                    self.selectedPlan = first
                }

                self.isLoadingProducts = false
            }
        }
    }

    /// Маппинг ApphudProduct → SubscriptionPlan (title/subtitle/бейдж)
    private func mapProductToPlan(_ apphudProduct: ApphudProduct) -> SubscriptionPlan {
        let productId = apphudProduct.productId
        let sk = apphudProduct.skProduct

        var priceString = ""
        var periodString = "Subscription"

        if let sk {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.locale = sk.priceLocale
            priceString = formatter.string(from: sk.price) ?? ""

            // Используем исправленный метод для определения периода
            periodString = ApphudManager.fixSubscriptionPeriodString(apphudProduct)
        }

        let title: String
        if priceString.isEmpty {
            title = periodString
        } else {
            title = "Just \(priceString) / \(periodString)"
        }

        let subtitle = "Auto renewable. Cancel anytime."

        var badge: String? = nil
        if let s = sk?.subscriptionPeriod, s.unit == .year {
            badge = "SAVE 40%"
        }

        return SubscriptionPlan(
            id: productId,
            title: title,
            subtitle: subtitle,
            badgeText: badge,
            product: apphudProduct
        )
    }
    
    // MARK: - Покупка
    
    private func handleContinue() {
        guard let apphudProduct = selectedPlan?.product else { return }

        Apphud.purchase(apphudProduct) { result in
            DispatchQueue.main.async {
                if let subscription = result.subscription, subscription.isActive() {
                    appState.hasActiveSubscription = true
                    dismiss()
                } else if let purchase = result.nonRenewingPurchase, purchase.isActive() {
                    appState.hasActiveSubscription = true
                    dismiss()
                } else if let error = result.error {
                    print("❌ Purchase error: \(error)")
                } else {
                    print("⚠️ Purchase completed but no active subscription/nonRenewingPurchase.")
                }
            }
        }
    }

    // MARK: - Restore Purchases

    private func restorePurchases() {
        ApphudManager.shared.restorePurchases(appState: appState) { hasPremium in
            if hasPremium {
                dismiss()
            }
        }
    }
}

