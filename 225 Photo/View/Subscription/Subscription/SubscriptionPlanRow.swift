//
//  Untitled.swift
//  225 Photo
//
//  Created by Сергей on 08.12.2025.
//

import SwiftUI
import StoreKit
import ApphudSDK

// MARK: - Ячейка плана

struct SubscriptionPlanRow: View {
    let plan: SubscriptionPlan
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .topTrailing) {
                HStack(spacing: 14) {
                    radioView
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(plan.title)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        Text(plan.subtitle)
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(isSelected ? Color("OnboardingYellow") : .clear,
                                lineWidth: 2)
                )
                .clipShape(RoundedRectangle(cornerRadius: 24))
                
                if let badge = plan.badgeText {
                    HStack {
                        Spacer()
                        Text(badge)
                            .font(.system(size: 11, weight: .bold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(
                                Capsule().fill(Color("OnboardingYellow"))
                            )
                            .foregroundColor(.white)
                    }
                    .padding(.trailing, 18)
                    .padding(.top, -5)
                }
            }
        }
        .buttonStyle(.plain)
    }
    
    private var cardBackground: some View {
        Group {
            if isSelected {
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color("OnboardingYellow").opacity(0.16))
            } else {
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.white.opacity(0.06))
            }
        }
    }
    
    private var radioView: some View {
        Group {
            if isSelected {
                ZStack {
                    Circle()
                        .fill(Color("OnboardingYellow"))
                        .frame(width: 26, height: 26)
                    
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.black)
                }
            } else {
                Circle()
                    .stroke(Color.white.opacity(0.6), lineWidth: 2)
                    .frame(width: 24, height: 24)
            }
        }
    }
}
