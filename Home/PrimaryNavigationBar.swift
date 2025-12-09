//
//  PrimaryNavigationBar.swift
//  225 Photo
//
//  Created by Сергей on 27.11.2025.
//

import SwiftUI

struct PrimaryNavigationBar: View {
    @EnvironmentObject var appState: AppState

    let title: String?
    let onBack: (() -> Void)?
    let onCrownTap: (() -> Void)?

    init(title: String? = nil,
         onBack: (() -> Void)? = nil,
         onCrownTap: (() -> Void)? = nil) {
        self.title = title
        self.onBack = onBack
        self.onCrownTap = onCrownTap
    }

    var body: some View {
        HStack {
            if let onBack = onBack {
                Button(action: onBack) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.08))
                            .frame(width: 36, height: 36)

                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                .buttonStyle(.plain)
            } else {
                Circle()
                    .fill(Color.clear)
                    .frame(width: 36, height: 36)
            }

            Spacer()

            if let title = title {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
            }

            // Правая кнопка PRO / Tokens или плейсхолдер
            if let onCrownTap = onCrownTap {
                Button(action: onCrownTap) {
                    if appState.hasActiveSubscription {
                        TokenBalanceBadge(tokens: appState.tokensBalance)
                    } else {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color("OnboardingYellow"))
                                .frame(width: 36, height: 36)

                            Image(systemName: "crown.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                }
                .buttonStyle(.plain)
            } else {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.clear)
                    .frame(width: 36, height: 36)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 16)
    }
}
