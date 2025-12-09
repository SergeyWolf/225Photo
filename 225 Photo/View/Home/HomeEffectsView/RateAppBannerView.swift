//
//  RateAppBannerView.swift
//  225 Photo
//
//  Created by Сергей on 08.12.2025.
//

import SwiftUI
import UIKit

// MARK: - Rate App Banner

struct RateAppBannerView: View {
    let onDismiss: () -> Void
    private func rateApp() {
        guard let url = AppConstants.Support.openStoreURL else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()

            VStack {
                Spacer()

                ZStack(alignment: .bottom) {
                    Image("img_banner")
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))

                    VStack(spacing: 12) {
                        Image("appstore")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 64, height: 64)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .shadow(color: Color.black.opacity(0.25), radius: 10, x: 0, y: 6)
                            .offset(y: -40)
                            .padding(.bottom, -40)

                        VStack(spacing: 6) {
                            Text("Do you like our app?")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.black)

                            Text("Please rate our app so we can improve it for you and make it even cooler")
                                .font(.system(size: 14))
                                .foregroundColor(.black.opacity(0.7))
                                .multilineTextAlignment(.center)
                        }

                        Button(action: {
                            rateApp()
                            onDismiss()
                        }) {
                            HStack {
                                Spacer()
                                Text("Rate app")
                                    .font(.system(size: 16, weight: .semibold))
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                                Spacer()
                            }
                            .padding(.vertical, 12)
                            .background(Color("OnboardingYellow"))
                            .foregroundColor(.white)
                            .cornerRadius(16)
                        }
                        .padding(.top, 4)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 18)
                    .background(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .fill(Color.white)
                    )
                    .shadow(color: Color.black.opacity(0.25), radius: 18, x: 0, y: 10)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                }
                .padding(.horizontal, 16)

                Spacer().frame(height: 24)
            }
        }
    }
}

