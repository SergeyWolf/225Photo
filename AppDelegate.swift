//
//  AppDelegate.swift
//  225 Photo
//
//  Created by Сергей on 05.12.2025.
//

import UIKit
import ApphudSDK
import AdSupport

// MARK: - AppDelegate для Apphud

class AppDelegate: NSObject, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {

        Apphud.start(apiKey: AppConstants.Apphud.apiKey)
        Defaults.userId = Apphud.userID()
        
        var launches = Defaults.homeRateBannerLaunchCount
        launches += 1
        Defaults.homeRateBannerLaunchCount = launches

        if launches == 1 || launches % 3 == 0 {
            Defaults.shouldShowRateBannerOnNextHome = true
        } else {
            Defaults.shouldShowRateBannerOnNextHome = false
        }

        return true
    }
}
