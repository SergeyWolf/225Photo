//
//  _25_PhotoApp.swift
//  225 Photo
//
//  Created by Сергей on 24.11.2025.
//

import SwiftUI
import UIKit
import ApphudSDK

@available(iOS 17.0, *)
@main
struct _25_PhotoApp: App {
    @StateObject private var appState = AppState()
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithOpaqueBackground()
        tabAppearance.backgroundColor = .black
        tabAppearance.shadowColor = .clear
        let selectedColor = UIColor(named: "OnboardingYellow") ?? .systemYellow
        let normalColor = UIColor(white: 1.0, alpha: 0.7)

        let normalAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: normalColor,
            .font: UIFont.systemFont(ofSize: 11, weight: .medium)
        ]
        let selectedAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: selectedColor,
            .font: UIFont.systemFont(ofSize: 11, weight: .semibold)
        ]

        tabAppearance.stackedLayoutAppearance.normal.titleTextAttributes = normalAttributes
        tabAppearance.stackedLayoutAppearance.selected.titleTextAttributes = selectedAttributes

        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance

        UITabBar.appearance().tintColor = selectedColor
        UITabBar.appearance().unselectedItemTintColor = normalColor
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .onAppear {
                    // При старте приложения синхронизируем состояние подписки с Apphud
                    ApphudManager.shared.refreshSubscriptionState(appState: appState)
                }
        }
    }
}

