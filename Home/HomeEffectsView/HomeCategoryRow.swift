//
//  Untitled.swift
//  225 Photo
//
//  Created by Сергей on 27.11.2025.
//

import SwiftUI

@available(iOS 17.0, *)
struct HomeCategoryRow: View {
    /// Все категории из ответа API — нужны, чтобы передать в AllTemplatesView
    let allCategories: [TemplateCategory]
    /// Конкретная категория, которая отображается в этом блоке
    let category: TemplateCategory

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            effectsRow
        }
    }

    // MARK: - Header (Title + See all)

    private var header: some View {
        HStack {
            Text(category.title)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)

            Spacer()

            NavigationLink {
                AllTemplatesView(
                    categories: allCategories,
                    initialCategory: category
                )
            } label: {
                HStack(spacing: 6) {
                    Text("See all")
                        .font(.system(size: 13, weight: .semibold))

                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.12))
                .cornerRadius(16)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Горизонтальный список эффектов

    private var effectsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(category.effects) { effect in
                    NavigationLink {
                        EffectDetailView(
                            effect: effect,
                            allEffects: category.effects
                        )
                    } label: {
                        EffectCardView(effect: effect)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

