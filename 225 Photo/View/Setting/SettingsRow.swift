//
//  SettingsRow.swift
//  225 Photo
//
//  Created by Сергей on 08.12.2025.
//

import SwiftUI
import UIKit

// MARK: - SettingsRow

struct SettingsRow<Accessory: View>: View {
    let title: String
    let subtitle: String?
    let systemImageName: String
    @ViewBuilder let accessory: () -> Accessory

    init(
        title: String,
        subtitle: String? = nil,
        systemImageName: String,
        @ViewBuilder accessory: @escaping () -> Accessory
    ) {
        self.title = title
        self.subtitle = subtitle
        self.systemImageName = systemImageName
        self.accessory = accessory
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 32, height: 32)
                Image(systemName: systemImageName)
                    .foregroundColor(Color("OnboardingYellow"))
                    .font(.system(size: 15, weight: .semibold))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.white.opacity(0.7))
                }
            }

            Spacer()

            accessory()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.06))
        .cornerRadius(18)
    }
}
