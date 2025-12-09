//
//  MainTabHeader.swift
//  225 Photo
//
//  Created by Сергей on 07.12.2025.
//

import SwiftUI

struct MainTabHeader: View {
    let title: String
    var onProTap: (() -> Void)? = nil

    @EnvironmentObject var appState: AppState

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)

            Spacer()

            Group {
                if appState.hasActiveSubscription {
                    tokenBadge
                } else {
                    proBadge
                }
            }
        }
        .padding(.horizontal, 2)
    }

    // MARK: - Right badge views

    @ViewBuilder
    private var proBadge: some View {
        if let onProTap {
            Button(action: onProTap) {
                ProStatusBadge(isPro: appState.hasActiveSubscription)
            }
            .buttonStyle(.plain)
        } else {
            ProStatusBadge(isPro: appState.hasActiveSubscription)
        }
    }

    @ViewBuilder
    private var tokenBadge: some View {
        let badge = TokenBalanceBadge(tokens: appState.tokensBalance)

        if let onProTap {
            Button(action: onProTap) {
                badge
            }
            .buttonStyle(.plain)
        } else {
            badge
        }
    }
}

/// Бейдж с количеством токенов, когда подписка активна
struct TokenBalanceBadge: View {
    let tokens: Int

    var body: some View {
        HStack(spacing: 6) {
            Text("\(tokens)")
            Image(systemName: "sparkles")
        }
        .font(.system(size: 15, weight: .bold))
        .foregroundColor(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color("OnboardingYellow").opacity(0.7),
                    Color("OnboardingYellow")
                ]),
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .clipShape(Capsule())
    }
}
