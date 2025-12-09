//
//  SubscriptionPlan.swift
//  225 Photo
//
//  Created by Сергей on 08.12.2025.
//

import SwiftUI
import StoreKit
import ApphudSDK

// MARK: - Модель плана подписки

struct SubscriptionPlan: Identifiable, Equatable {
    let id: String
    let title: String
    let subtitle: String
    let badgeText: String?    
    let product: ApphudProduct?

    static func == (lhs: SubscriptionPlan, rhs: SubscriptionPlan) -> Bool {
        lhs.id == rhs.id
    }
}
