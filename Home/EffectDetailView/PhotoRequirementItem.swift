//
//  PhotoRequirementItem.swift
//  225 Photo
//
//  Created by Сергей on 04.12.2025.
//

import SwiftUI
import UIKit

// MARK: - Элемент "Bad/Good photo"

struct PhotoRequirementItem: View {
    let imageName: String
    let title: String
    let isGood: Bool

    var body: some View {
        VStack(spacing: 10) {
            ZStack(alignment: .bottom) {
                Image(imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 96, height: 96)
                    .clipShape(Circle())
            }
            .padding(.bottom, 18)

            Text(title)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .frame(width: 96)
        }
    }
}
