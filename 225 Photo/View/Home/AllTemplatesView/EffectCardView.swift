//
//  EffectCardView.swift
//  225 Photo
//
//  Created by Сергей on 27.11.2025.
//

import SwiftUI

// MARK: - Карточка эффекта

struct EffectCardView: View {
    let effect: TemplateEffect

    /// URL превью: сначала берём production, потом обычный preview, потом previewBefore
    private var previewURL: URL? {
        if let prod = effect.previewProduction, let url = URL(string: prod) {
            return url
        }
        if let prev = effect.preview, let url = URL(string: prev) {
            return url
        }
        if let before = effect.previewBefore, let url = URL(string: before) {
            return url
        }
        return nil
    }

    private let cardWidth: CGFloat = 150
    private let cardHeight: CGFloat = 210
    private let cornerRadius: CGFloat = 18

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            CachedAsyncImage(
                url: previewURL,
                cornerRadius: cornerRadius,
                contentMode: .fill
            ) {
                placeholderView
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black.opacity(0.0),
                    Color.black.opacity(0.9)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 80)
            .allowsHitTesting(false)

            Text(effect.title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.bottom, 8)
        }
        .frame(width: cardWidth, height: cardHeight)
        .background(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }

    // MARK: - Placeholder

    /// Плейсхолдер, пока картинка грузится (или не загрузилась)
    private var placeholderView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color.white.opacity(0.08))

            ProgressView()
                .progressViewStyle(.circular)
                .tint(Color("OnboardingYellow"))
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        EffectCardView(
            effect: TemplateEffect(
                id: 1,
                title: "Tattooist",
                preview: nil,
                previewProduction: nil,
                previewBefore: nil,
                gender: "f",
                prompt: nil,
                isEnabled: true
            )
        )
    }
    .preferredColorScheme(.dark)
}

