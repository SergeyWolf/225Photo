//
//  OnboardingStep.swift
//  225 Photo
//
//  Created by Сергей on 24.11.2025.
//

import SwiftUI
import StoreKit
import UserNotifications
import UIKit

enum OnboardingStep: Int, CaseIterable {
    case photo = 0          // onboarding-1
    case manyEffects        // onboarding-2
    case shareFriends       // onboarding-3
    case rateApp            // onboarding-4 (alert)
    case notifications      // onboarding-5 (+ системный алерт пушей)
}
