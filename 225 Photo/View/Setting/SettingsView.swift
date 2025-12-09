//
//  SettingsView.swift
//  225 Photo
//
//  Created by Sergey on 28.11.2025.
//

import SwiftUI
import UIKit

struct SettingsView: View {
    @EnvironmentObject var appState: AppState

    @State private var notificationsEnabled = Defaults.notificationsEnabled
    @State private var cacheSizeText: String = "0 MB"
    @State private var showShareSheet = false
    @State private var showPaywall = false
    @State private var activeAlert: SettingsAlert?

    @Environment(\.openURL) private var openURL

    // MARK: - Версия приложения и userId

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private var appVersionLabel: String {
        "App Version: \(appVersion)"
    }

    private var userId: String {
        return Defaults.userId
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        header

                        if appState.hasActiveSubscription {
                            subscriptionDetailsCard
                        } else {
                            upgradeCard
                        }

                        supportSection
                        actionsSection
                        infoSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 32)
                }

                Text(appVersionLabel)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.white.opacity(0.6))
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 8)
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: [shareText, AppConstants.Support.appStoreURL])
        }
        .fullScreenCover(isPresented: $showPaywall) {
            if appState.hasActiveSubscription {
                TokensPaywallView()
            } else {
                SubscriptionPaywallView()
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            updateCacheSizeLabel()
        }
        .alert(item: $activeAlert) { alert in
            switch alert {
            case .notifications:
                return Alert(
                    title: Text("Allow notifications?"),
                    message: Text("This app will be able to send you messages in your notification center"),
                    primaryButton: .default(Text("Allow"), action: {
                        NotificationService.requestPushPermission { granted in
                            DispatchQueue.main.async {
                                Defaults.notificationsEnabled = granted
                                notificationsEnabled = granted
                            }
                        }
                    }),
                    secondaryButton: .cancel({
                        notificationsEnabled = false
                        Defaults.notificationsEnabled = false
                    })
                )

            case .clearCache:
                return Alert(
                    title: Text("Clear cache?"),
                    message: Text("The cached files of your videos will be deleted from your phone's memory. But your download history will be retained."),
                    primaryButton: .destructive(Text("Clear"), action: {
                        clearCache()
                    }),
                    secondaryButton: .cancel()
                )
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            MainTabHeader(title: "Settings") {
                showPaywall = true
            }
        }
    }

    // MARK: - Upgrade / Subscription cards
    private var upgradeCard: some View {
        Button {
            showPaywall = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)

                Text("Upgrade plan")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(
                LinearGradient(
                    colors: [
                        Color("OnboardingYellow").opacity(0.9),
                        Color("OnboardingYellow")
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var subscriptionDetailsCard: some View {
        let currentTokens = appState.tokensBalance
        // стоимость одной генерации в токенах (у нас 2 токена)
        let costPerGeneration = AppConstants.MinCounToken.token

        return VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Subscription details")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)

                    Text("Information on subscription\nbenefits and prices")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.6))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color("OnboardingYellow"))
                        .frame(width: 40, height: 40)

                    Image(systemName: "crown.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Tokens to generate:")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)

                    Spacer()

                    Text("\(currentTokens)")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }

                HStack(spacing: 4) {
                    Text("Cost of generation:")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))

                    Text("\(costPerGeneration) tokens")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color("OnboardingYellow"))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.white.opacity(0.08))
            .cornerRadius(20)

            Button {
                showPaywall = true
            } label: {
                Text("Buy")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color("OnboardingYellow"))
                    .cornerRadius(20)
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color("OnboardingYellow"), lineWidth: 1)
                )
        )
    }

    // MARK: - Sections

    private var supportSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Support us")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.7))

            VStack(spacing: 10) {
                Button {
                    RateUsService.requestSystemReview()
                } label: {
                    SettingsRow(
                        title: "Rate app",
                        systemImageName: "star.fill"
                    ) {
                        Image(systemName: "chevron.right")
                            .foregroundColor(.white.opacity(0.6))
                            .font(.system(size: 14, weight: .semibold))
                    }
                }
                .buttonStyle(.plain)

                Button {
                    showShareSheet = true
                } label: {
                    SettingsRow(
                        title: "Share with friends",
                        systemImageName: "square.and.arrow.up"
                    ) {
                        Image(systemName: "chevron.right")
                            .foregroundColor(.white.opacity(0.6))
                            .font(.system(size: 14, weight: .semibold))
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var actionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Actions")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.7))

            VStack(spacing: 10) {
                // Notifications toggle
                SettingsRow(
                    title: "Notifications",
                    systemImageName: "bell.fill"
                ) {
                    Toggle("", isOn: $notificationsEnabled)
                        .labelsHidden()
                        .tint(Color("OnboardingYellow"))
                }
                .onChange(of: notificationsEnabled) { newValue in
                    if newValue {
                        if !Defaults.notificationsEnabled {
                            activeAlert = .notifications
                        }
                    } else {
                        Defaults.notificationsEnabled = false
                    }
                }

                // Clear cache
                Button {
                    activeAlert = .clearCache
                } label: {
                    SettingsRow(
                        title: "Clear cache",
                        systemImageName: "trash"
                    ) {
                        HStack(spacing: 6) {
                            Text(cacheSizeText)
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(.white.opacity(0.7))
                            Image(systemName: "chevron.right")
                                .foregroundColor(.white.opacity(0.6))
                                .font(.system(size: 14, weight: .semibold))
                        }
                    }
                }
                .buttonStyle(.plain)

                Button {
                    ApphudManager.shared.restorePurchases(appState: appState, completion: nil)
                } label: {
                    SettingsRow(
                        title: "Restore purchases",
                        systemImageName: "arrow.clockwise"
                    ) {
                        Image(systemName: "chevron.right")
                            .foregroundColor(.white.opacity(0.6))
                            .font(.system(size: 14, weight: .semibold))
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Info & legal")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.7))

            VStack(spacing: 10) {
                // Contact us
                Button {
                    openContactEmail()
                } label: {
                    SettingsRow(
                        title: "Contact us",
                        systemImageName: "envelope.fill"
                    ) {
                        Image(systemName: "chevron.right")
                            .foregroundColor(.white.opacity(0.6))
                            .font(.system(size: 14, weight: .semibold))
                    }
                }
                .buttonStyle(.plain)

                Button {
                    openURL(AppConstants.Legal.privacyPolicyURL)
                } label: {
                    SettingsRow(
                        title: "Privacy Policy",
                        systemImageName: "lock.fill"
                    ) {
                        Image(systemName: "chevron.right")
                            .foregroundColor(.white.opacity(0.6))
                            .font(.system(size: 14, weight: .semibold))
                    }
                }
                .buttonStyle(.plain)

                Button {
                    openURL(AppConstants.Legal.termsOfUseURL)
                } label: {
                    SettingsRow(
                        title: "Usage Policy",
                        systemImageName: "doc.text.fill"
                    ) {
                        Image(systemName: "chevron.right")
                            .foregroundColor(.white.opacity(0.6))
                            .font(.system(size: 14, weight: .semibold))
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Helpers

    private var shareText: String {
        "Check out 225 Photo – AI photo effects!"
    }

    private func clearCache() {
        URLCache.shared.removeAllCachedResponses()
        clearDiskCaches()
        appState.clearHistory()
        updateCacheSizeLabel()
    }

    private func updateCacheSizeLabel() {
        cacheSizeText = "Calculating..."

        DispatchQueue.global(qos: .utility).async {
            let sizeBytes = calculateCacheSizeBytes()
            let mb = Double(sizeBytes) / (1024.0 * 1024.0)

            let text: String
            if sizeBytes == 0 {
                text = "0 MB"
            } else if mb < 0.1 {
                text = "< 0.1 MB"
            } else {
                text = String(format: "%.1f MB", mb)
            }

            DispatchQueue.main.async {
                self.cacheSizeText = text
            }
        }
    }

    private func calculateCacheSizeBytes() -> Int {
        var total = 0

        total += URLCache.shared.currentDiskUsage

        let fm = FileManager.default

        if let cachesURL = fm.urls(for: .cachesDirectory, in: .userDomainMask).first {
            total += directorySize(at: cachesURL)
        }

        let tmpURL = fm.temporaryDirectory
        total += directorySize(at: tmpURL)

        return total
    }

    private func directorySize(at url: URL) -> Int {
        let fm = FileManager.default
        guard let enumerator = fm.enumerator(
            at: url,
            includingPropertiesForKeys: [.isRegularFileKey, .fileSizeKey],
            options: [],
            errorHandler: nil
        ) else {
            return 0
        }

        var total = 0

        for case let fileURL as URL in enumerator {
            do {
                let values = try fileURL.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey])
                if values.isRegularFile == true {
                    total += values.fileSize ?? 0
                }
            } catch {
                continue
            }
        }

        return total
    }

    private func clearDiskCaches() {
        let fm = FileManager.default

        if let cachesURL = fm.urls(for: .cachesDirectory, in: .userDomainMask).first {
            if let contents = try? fm.contentsOfDirectory(at: cachesURL, includingPropertiesForKeys: nil) {
                for url in contents {
                    try? fm.removeItem(at: url)
                }
            }
        }

        let tmpURL = fm.temporaryDirectory
        if let contents = try? fm.contentsOfDirectory(at: tmpURL, includingPropertiesForKeys: nil) {
            for url in contents {
                try? fm.removeItem(at: url)
            }
        }
    }

    private func openContactEmail() {
        let email = AppConstants.Support.email
        let subject = "225 Photo Support"

        let body = """
        User ID: \(userId)
        App Version: \(appVersion)

        Please describe your issue below:
        """

        let subjectEncoded = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let bodyEncoded = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        if let url = URL(string: "mailto:\(email)?subject=\(subjectEncoded)&body=\(bodyEncoded)") {
            openURL(url)
        }
    }
}

// MARK: - Тип алерта в настройках

private enum SettingsAlert: Identifiable {
    case notifications
    case clearCache

    var id: Int { hashValue }
}

