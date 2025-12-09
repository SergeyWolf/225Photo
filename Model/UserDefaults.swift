//
//  UserDefaults.swift
//  225 Photo
//
//  Created by Сергей on 30.11.2025.
//

import Foundation


enum DefaultsKey: String {
    case userId = "225photo_userId"
    case hasSeenPhotoRequirements
    case notificationsEnabled
    case generationHistory = "generationHistory_v1"
    case tokensBalance = "tokens_balance_v1"
    case homeRateBannerLaunchCount = "home_rate_banner_launch_count_v1"
    case shouldShowRateBannerOnNextHome = "should_show_rate_banner_on_next_home_v1"
}

enum Defaults {
    private static let storage = UserDefaults.standard

    // MARK: - User ID

    /// userId приложения.
    /// По задумке: в AppDelegate один раз кладём сюда Apphud.userID().
    /// Если по какой-то причине его ещё нет, генерим временный UUID.
    static var userId: String {
        get {
            if let stored = storage.string(forKey: DefaultsKey.userId.rawValue) {
                return stored
            }

            let fallback = UUID().uuidString
            storage.set(fallback, forKey: DefaultsKey.userId.rawValue)
            return fallback
        }
        set {
            storage.set(newValue, forKey: DefaultsKey.userId.rawValue)
        }
    }

    // MARK: - Photo requirements

    /// Показывали ли уже экран Photo requirements (true после первого Okay)
    static var hasSeenPhotoRequirements: Bool {
        get {
            storage.bool(forKey: DefaultsKey.hasSeenPhotoRequirements.rawValue)
        }
        set {
            storage.set(newValue, forKey: DefaultsKey.hasSeenPhotoRequirements.rawValue)
        }
    }

    // MARK: - Notifications

    /// Наш флаг "Notifications" в настройках (для UI), не системный permission
    static var notificationsEnabled: Bool {
        get {
            storage.bool(forKey: DefaultsKey.notificationsEnabled.rawValue)
        }
        set {
            storage.set(newValue, forKey: DefaultsKey.notificationsEnabled.rawValue)
        }
    }

    // MARK: - Generation history

    /// История генераций, сохраняем как JSON
    static var generationHistory: [GenerationHistoryItem] {
        get {
            guard let data = storage.data(forKey: DefaultsKey.generationHistory.rawValue) else {
                return []
            }
            do {
                return try JSONDecoder().decode([GenerationHistoryItem].self, from: data)
            } catch {
                return []
            }
        }
        set {
            do {
                let data = try JSONEncoder().encode(newValue)
                storage.set(data, forKey: DefaultsKey.generationHistory.rawValue)
            } catch {
                print("❌ Failed to encode generationHistory: \(error)")
            }
        }
    }
    
    // MARK: - Сохранение токенов
    static var tokensBalance: Int {
        get {
            storage.integer(forKey: DefaultsKey.tokensBalance.rawValue)
        }
        set {
            storage.set(newValue, forKey: DefaultsKey.tokensBalance.rawValue)
        }
    }
    
    // MARK: - Rate banner / Home visits

    /// Счётчик заходов на главный экран для показа баннера оценки
    static var homeRateBannerLaunchCount: Int {
        get {
            storage.integer(forKey: DefaultsKey.homeRateBannerLaunchCount.rawValue)
        }
        set {
            storage.set(newValue, forKey: DefaultsKey.homeRateBannerLaunchCount.rawValue)
        }
    }
    
    static var shouldShowRateBannerOnNextHome: Bool {
        get {
            storage.bool(forKey: DefaultsKey.shouldShowRateBannerOnNextHome.rawValue)
        }
        set {
            storage.set(newValue, forKey: DefaultsKey.shouldShowRateBannerOnNextHome.rawValue)
        }
    }

    // MARK: - Служебные методы (по желанию)

    /// Удалить значение по ключу
    static func remove(_ key: DefaultsKey) {
        storage.removeObject(forKey: key.rawValue)
    }
}

