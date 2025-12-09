//
//  HistoryCardView.swift
//  225 Photo
//
//  Created by Сергей on 05.12.2025.
//

//import SwiftUICore
import SwiftUI

private let historyCellWidth: CGFloat = 116
private let historyCellHeight: CGFloat = 206
private let historyCornerRadius: CGFloat = 20

@available(iOS 17.0, *)
struct HistoryCardView: View {
    @EnvironmentObject var appState: AppState

    let item: GenerationHistoryItem
    let onTap: () -> Void

    private var hasTitle: Bool {
        !item.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var imageURL: URL? {
        item.resultURL ?? item.previewURL
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: historyCornerRadius)
                .fill(Color.white.opacity(0.08))

            CachedAsyncImage(
                url: imageURL,
                cornerRadius: historyCornerRadius,
                contentMode: .fill
            ) {
                Color.white.opacity(0.05)
            }
            .frame(width: historyCellWidth, height: historyCellHeight)

            if hasTitle {
                VStack {
                    Spacer()
                    HStack {
                        Text(item.title)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                        Spacer(minLength: 0)
                    }
                    .background(
                        LinearGradient(
                            colors: [
                                Color.black.opacity(0.0),
                                Color.black.opacity(0.75)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .clipShape(
                        RoundedRectangle(cornerRadius: historyCornerRadius)
                    )
                }
            }

            overlay
        }
        .frame(width: historyCellWidth, height: historyCellHeight)
        .clipShape(RoundedRectangle(cornerRadius: historyCornerRadius))
        .contentShape(RoundedRectangle(cornerRadius: historyCornerRadius))
        .onTapGesture {
            onTap()
        }
    }

    @ViewBuilder
    private var overlay: some View {
        switch item.status {
        case .inProgress:
            Color.black.opacity(0.45)
                .clipShape(RoundedRectangle(cornerRadius: historyCornerRadius))
                .overlay(
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                )

        case .error:
            Color.black.opacity(0.55)
                .clipShape(RoundedRectangle(cornerRadius: historyCornerRadius))
                .overlay(
                    VStack(spacing: 6) {
                        Text("Error")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)

                        Button {
                            onTap()
                        } label: {
                            Text("Read more")
                                .font(.system(size: 12, weight: .semibold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color.white)
                                .foregroundColor(.black)
                                .cornerRadius(12)
                        }
                    }
                )

        case .success:
            EmptyView()
        }
    }
}
