//
//  HistoryErrorSheet.swift
//  225 Photo
//
//  Created by Сергей on 05.12.2025.
//

//import SwiftUICore
import SwiftUI

struct HistoryErrorSheet: View {
    let item: GenerationHistoryItem
    let onRefresh: () -> Void
    let onDelete: () -> Void
    let onCancel: () -> Void

    private var messageText: String {
        item.errorMessage ??
        "Something went wrong or the server is not responding. Try again or do it later. Unfortunately, the generation was not completed"
    }

    var body: some View {
        VStack {
            Spacer()

            VStack(spacing: 0) {
                Text("Select action")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.top, 14)
                    .padding(.bottom, 6)

                Text(messageText)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 10)
                    .fixedSize(horizontal: false, vertical: true)

                Divider()
                    .overlay(Color.white.opacity(0.10))

                Button(action: onRefresh) {
                    Text("Refresh")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color("OnboardingYellow"))
                        .frame(maxWidth: .infinity, minHeight: 48)
                }

                Divider()
                    .overlay(Color.white.opacity(0.10))

                Button(role: .destructive, action: onDelete) {
                    Text("Delete")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity, minHeight: 48)
                }
                .padding(.bottom, 8)
            }
            .background(.ultraThinMaterial)
            .cornerRadius(24)
            .padding(.horizontal, 12)

            Button(action: onCancel) {
                Text("Cancel")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color("OnboardingYellow"))
                    .frame(maxWidth: .infinity, minHeight: 52)
            }
            .background(.ultraThinMaterial)
            .cornerRadius(24)
            .padding(.horizontal, 12)
            .padding(.top, 8)
            .padding(.bottom, 16)
        }
    }
}

