//
//  SelectPhotoActionSheet.swift
//  225 Photo
//
//  Created by Сергей on 04.12.2025.
//

import SwiftUI

// MARK: - Bottom sheet "Select action"

@available(iOS 17.0, *)
struct SelectPhotoActionSheet: View {
    let onTakePhoto: () -> Void
    let onChooseFromGallery: () -> Void
    let onCancel: () -> Void

    var body: some View {
        ZStack {
            Color.clear.ignoresSafeArea()

            VStack(spacing: 8) {
                VStack(spacing: 0) {
                    VStack(spacing: 6) {
                        Text("Select action")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)

                        Text("Add a photo so we can do a cool effect with it")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 10)

                    Divider()
                        .background(Color.white.opacity(0.2))

                    Button(action: onTakePhoto) {
                        Text("Take a photo")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(Color("OnboardingYellow"))
                            .frame(maxWidth: .infinity, minHeight: 48)
                    }

                    Divider()
                        .background(Color.white.opacity(0.2))

                    Button(action: onChooseFromGallery) {
                        Text("Select from gallery")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(Color("OnboardingYellow"))
                            .frame(maxWidth: .infinity, minHeight: 48)
                    }
                    .padding(.bottom, 6)
                }
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

                Button(action: onCancel) {
                    Text("Cancel")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Color("OnboardingYellow"))
                        .frame(maxWidth: .infinity, minHeight: 48)
                }
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
    }
}

