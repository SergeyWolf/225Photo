//
//  ApphudManager.swift
//  225 Photo
//
//  Created by Сергей on 07.12.2025.
//

import Foundation
import ApphudSDK

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
}

