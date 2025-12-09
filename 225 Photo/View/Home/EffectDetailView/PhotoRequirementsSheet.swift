//
//  PhotoRequirementsSheet.swift
//  225 Photo
//
//  Created by Сергей on 04.12.2025.
//

import SwiftUI
import UIKit

// MARK: - Bottom sheet "Photo requirements"

@available(iOS 17.0, *)
struct PhotoRequirementsSheet: View {
    let onOkay: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                    .padding(.horizontal, 24)
                    .padding(.top, 16)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        badPhotosSection
                        goodPhotosSection
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    .padding(.bottom, 32)
                }
                .frame(maxHeight: UIScreen.main.bounds.height * 0.55)

                okayButton
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
            }
        }
    }

    // MARK: - Subviews

    private var header: some View {
        ZStack {
            Text("Photo requirements")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .center)

            HStack {
                Spacer()

                Button {
                    dismiss()
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.16))

                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .frame(width: 32, height: 32)
                }
            }
        }
    }

    private var badPhotosSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Bad photos")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)

            HStack(spacing: 20) {
                PhotoRequirementItem(
                    imageName: "photo_req_bad_1",
                    title: "Face is hidden",
                    isGood: false
                )
                PhotoRequirementItem(
                    imageName: "photo_req_bad_2",
                    title: "Poor lighting",
                    isGood: false
                )
                PhotoRequirementItem(
                    imageName: "photo_req_bad_3",
                    title: "Bad angle",
                    isGood: false
                )
            }
        }
    }

    private var goodPhotosSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Good photos")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)

            HStack(spacing: 20) {
                PhotoRequirementItem(
                    imageName: "photo_req_good_1",
                    title: "Face is visible",
                    isGood: true
                )
                PhotoRequirementItem(
                    imageName: "photo_req_good_2",
                    title: "Good lighting",
                    isGood: true
                )
                PhotoRequirementItem(
                    imageName: "photo_req_good_3",
                    title: "Front view",
                    isGood: true
                )
            }
        }
    }

    private var okayButton: some View {
        Button {
            onOkay()
            dismiss()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "checkmark")
                    .font(.system(size: 15, weight: .semibold))

                Text("Okay")
                    .font(.system(size: 17, weight: .semibold))
            }
            .foregroundColor(.black)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(Color("OnboardingYellow"))
            .cornerRadius(16)
        }
    }
}
