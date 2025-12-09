//
//  NotificationService.swift
//  225 Photo
//
//  Created by Сергей on 24.11.2025.
//

import SwiftUI
import StoreKit
import UserNotifications

enum RateUsService {
    static func requestSystemReview() {
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first else { return }
        
        SKStoreReviewController.requestReview(in: scene)
    }
}

enum NotificationService {
    static func requestPushPermission(
        completion: @escaping (Bool) -> Void
    ) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            completion(granted)
        }
    }
    
    /// Локальный пуш о завершении генерации.
    /// Учитывает тумблер в настройках и системные permissions.
    static func scheduleGenerationFinishedNotification(
        title: String,
        body: String
    ) {
        // Проверяем, включены ли уведомления в настройках приложения
        guard Defaults.notificationsEnabled else { return }
        
        let center = UNUserNotificationCenter.current()
        
        center.getNotificationSettings { settings in
            let status = settings.authorizationStatus
            guard status == .authorized || status == .provisional else { return }
            
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            content.sound = .default
            
            let trigger = UNTimeIntervalNotificationTrigger(
                timeInterval: 0.5,
                repeats: false
            )
            
            let request = UNNotificationRequest(
                identifier: "generation_finished_\(UUID().uuidString)",
                content: content,
                trigger: trigger
            )
            
            center.add(request) { error in
                if let error {
                    print("Failed to schedule generation finished notification: \(error)")
                } else {
                    print("Scheduled generation finished notification.")
                }
            }
        }
    }
}

