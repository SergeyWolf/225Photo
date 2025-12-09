//
//  PromptStylesSheetView.swift
//  225 Photo
//
//  Created by Сергей on 01.12.2025.
//

import SwiftUI

@available(iOS 17.0, *)
struct PromptStylesSheetView: View {
    let effects: [TemplateEffect]
    @Binding var selectedStyleId: Int

    @Environment(\.dismiss) private var dismiss

    @State private var tempSelectedId: Int

    init(effects: [TemplateEffect], selectedStyleId: Binding<Int>) {
        self.effects = effects
        self._selectedStyleId = selectedStyleId
        _tempSelectedId = State(initialValue: selectedStyleId.wrappedValue)
    }

    private let columns: [GridItem] = Array(
        repeating: GridItem(.flexible(), spacing: 16),
        count: 4
    )

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                Capsule()
                    .fill(Color.white.opacity(0.25))
                    .frame(width: 36, height: 4)
                    .padding(.top, 8)

                ZStack {
                    Text("Styles")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)

                    HStack {
                        Spacer()

                        Button {
                            dismiss()
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.14))
                                Image(systemName: "xmark")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            .frame(width: 32, height: 32)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)

                ScrollView {
                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(effects) { effect in
                            StyleGridItem(
                                effect: effect,
                                isSelected: tempSelectedId == effect.id
                            )
                            .onTapGesture {
                                tempSelectedId = effect.id
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 16)
                }

                Button {
                    selectedStyleId = tempSelectedId
                    dismiss()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Select")
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity, minHeight: 54)
                }
                .buttonStyle(.plain)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color("OnboardingYellow"))
                )
                .foregroundColor(.black)
                .padding(.horizontal, 20)
                .padding(.top, 4)
                .padding(.bottom, 24)
            }
        }
    }

    private struct StyleGridItem: View {
        let effect: TemplateEffect
        let isSelected: Bool

        private var previewURL: URL? {
            let urlString = effect.previewProduction ?? effect.preview ?? effect.previewBefore
            return urlString.flatMap { URL(string: $0) }
        }

        var body: some View {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.07))

                    if let url = previewURL {
                        CachedAsyncImage(
                            url: url,
                            cornerRadius: 36,
                            contentMode: .fill
                        ) {
                            ProgressView()
                                .progressViewStyle(.circular)
                        }
                        .clipShape(Circle())
                    } else {
                        Image(systemName: "photo")
                            .resizable()
                            .scaledToFit()
                            .padding(16)
                            .foregroundColor(.white.opacity(0.7))
                    }

                    if isSelected {
                        Circle()
                            .stroke(Color("OnboardingYellow"), lineWidth: 3)
                    }
                }
                .frame(width: 72, height: 72)

                Text(effect.title)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(isSelected ? Color("OnboardingYellow") : .white)
                    .lineLimit(1)
            }
        }
    }
}

#Preview {
    if #available(iOS 17.0, *) {
        PromptStylesSheetView(
            effects: [],
            selectedStyleId: .constant(0)
        )
        .preferredColorScheme(.dark)
    } else {
        EmptyView()
    }
}
