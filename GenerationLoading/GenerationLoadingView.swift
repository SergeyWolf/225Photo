//
//  GenerationLoadingView.swift
//  225 Photo
//
//  Created by Сергей on 01.12.2025.
//

import SwiftUI

struct GenerationLoadingView: View {
    let errorMessage: String

    // Флаг показа алерта (биндим к стейту родителя)
    @Binding var isShowingErrorAlert: Bool

    let onCancel: () -> Void
    let onRetry: () -> Void

    init(
        errorMessage: String = "Something went wrong or the server is not responding. Try again or do it later.",
        isShowingErrorAlert: Binding<Bool>,
        onCancel: @escaping () -> Void,
        onRetry: @escaping () -> Void
    ) {
        self.errorMessage = errorMessage
        self._isShowingErrorAlert = isShowingErrorAlert
        self.onCancel = onCancel
        self.onRetry = onRetry
    }

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Spacer()

                    Button(action: onCancel) {
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
                .padding(.top, 12)
                .padding(.horizontal, 20)

                Spacer()

                VStack(spacing: 24) {
                    Text("Loading")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.white)

                    LottieView(name: "СatMarkLoading", loopMode: .loop)
                        .frame(width: 190, height: 190)

                    Text("Generation usually takes about a minute. You can close this screen, the generation will go to «History».")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }

                Spacer()
            }
        }
        .alert("Generation error", isPresented: $isShowingErrorAlert) {
            Button("Cancel", role: .cancel) {
                onCancel()
            }
            Button("Try Again") {
                onRetry()
            }
        } message: {
            Text(errorMessage)
        }
    }
}

#Preview {
    GenerationLoadingView(
        isShowingErrorAlert: .constant(true),
        onCancel: {},
        onRetry: {}
    )
    .preferredColorScheme(.dark)
}

