//
//  ApphudManager.swift
//  225 Photo
//
//  Created by Сергей on 07.12.2025.
//

import Foundation
import ApphudSDK
import StoreKit

final class ApphudManager {

    static let shared = ApphudManager()
    private init() {}

    /// Разово обновляет флаг подписки в AppState.
    /// Вызываем при старте приложения и после успешной покупки/restore.
    func refreshSubscriptionState(appState: AppState) {
        let hasPremium = Apphud.hasPremiumAccess()

        DispatchQueue.main.async {
            appState.hasActiveSubscription = hasPremium
        }
    }

    /// Общий restore-процесс, который можно дергать из разных мест (paywall, настройки и т.д.)
    /// - Parameters:
    ///   - appState: общий AppState из EnvironmentObject
    ///   - completion: true, если после restore есть премиум-доступ
    @MainActor func restorePurchases(appState: AppState, completion: ((Bool) -> Void)? = nil) {
        Apphud.restorePurchases { result in
            DispatchQueue.main.async {
                if let error = result.error {
                    completion?(false)
                    return
                }

                // обновляем стейт подписки
                self.refreshSubscriptionState(appState: appState)

                let hasPremium = Apphud.hasPremiumAccess()

                completion?(hasPremium)
            }
        }
    }
    
    /// Вспомогательный метод для исправления отображения периода подписки
    /// Если в Apphud приходит день, но по логике продукта это должна быть неделя - показываем "Weekly"
    static func fixSubscriptionPeriodString(_ product: ApphudProduct?) -> String {
        guard let skProduct = product?.skProduct,
              let subscriptionPeriod = skProduct.subscriptionPeriod else {
            return "Subscription"
        }
        
        // Исправление: если период день, но по productId это недельная подписка
        if subscriptionPeriod.unit == .day {
            // Проверяем productId на наличие признаков недельной подписки
            let productId = product?.productId.lowercased() ?? ""
            if productId.contains("week") ||
               productId.contains("weekly") ||
               productId.contains("7day") ||
               productId.contains("7_day") ||
               subscriptionPeriod.numberOfUnits == 7 {
                return "Weekly"
            }
        }
        
        // Стандартная логика
        switch subscriptionPeriod.unit {
        case .week:
            return "Weekly"
        case .month:
            return "Monthly"
        case .year:
            return "Annual"
        case .day:
            return "Daily"
        @unknown default:
            return "Subscription"
        }
    }
}
