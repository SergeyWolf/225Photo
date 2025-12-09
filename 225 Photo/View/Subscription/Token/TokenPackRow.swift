//
//  TokenPackRow.swift
//  225 Photo
//
//  Created by Сергей on 08.12.2025.
//

import SwiftUI
import ApphudSDK
import StoreKit

// MARK: - Ряд с пакетом токенов

struct TokenPackRow: View {
    let pack: TokenPack
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Text("\(pack.tokens) tokens")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)

                Spacer()

                if let badge = pack.badgeText {
                    Text(badge)
                        .font(.system(size: 11, weight: .bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule().fill(Color("OnboardingYellow"))
                        )
                        .foregroundColor(.black)
                }

                Text(pack.priceText)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.white.opacity(0.06))
            )
        }
        .buttonStyle(.plain)
    }
}
