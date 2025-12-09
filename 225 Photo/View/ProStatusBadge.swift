//
//  ProStatusBadge.swift
//  225 Photo
//
//  Created by Сергей on 08.12.2025.
//

import SwiftUI
import UIKit

// MARK: - Pro Badge

struct ProStatusBadge: View {
    let isPro: Bool

    var body: some View {
        HStack(spacing: 6) {
            Text("PRO")
            Image(systemName: "crown.fill")
        }
        .font(.system(size: 12, weight: .bold))
        .foregroundColor(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(Color("OnboardingYellow"))
        .clipShape(Capsule())
        .opacity(isPro ? 1 : 0.8)
    }
}
