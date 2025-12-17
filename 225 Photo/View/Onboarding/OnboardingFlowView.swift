//
//  Onboarding.swift
//  225 Photo
//
//  Created by Сергей on 24.11.2025.
//

import Foundation
import SwiftUI

struct OnboardingFlowView: View {
    @EnvironmentObject var appState: AppState
    let onFinish: () -> Void
    @State private var step: OnboardingStep = .photo
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            TabView(selection: $step) {
                // 1. Photo (с запросом ATT)
                OnboardingContentPage(
                    imageName: "onboarding_photo",
                    title: "Photo",
                    subtitle: "Generate with text and photos",
                    pageIndex: 0,
                    totalPages: 4,
                    nextActionTitle: "Next",
                    onNext: { goNext() },
                    shouldRequestATT: true
                )
                .tag(OnboardingStep.photo)
                
                // 2. Many effects
                OnboardingContentPage(
                    imageName: "onboarding_many_effects",
                    title: "Many effects",
                    subtitle: "Choose from a variety of effects",
                    pageIndex: 1,
                    totalPages: 4,
                    nextActionTitle: "Next",
                    onNext: { goNext() },
                    shouldRequestATT: false
                )
                .tag(OnboardingStep.manyEffects)
                
                // 3. Share with friends
                OnboardingContentPage(
                    imageName: "onboarding_rate_background",
                    title: "Share with friends",
                    subtitle: "Show your best generations to your friends",
                    pageIndex: 2,
                    totalPages: 4,
                    nextActionTitle: "Next",
                    onNext: { goNext() },
                    shouldRequestATT: false
                )
                .tag(OnboardingStep.shareFriends)
                
                // 4. Rate app
                OnboardingContentPage(
                    imageName: "onboarding_share",
                    title: "Rate our app in the App Store",
                    subtitle: nil,
                    pageIndex: 3,
                    totalPages: 4,
                    nextActionTitle: "Next",
                    onNext: { goNext() },
                    shouldRequestATT: false,
                    overlay: { RateAlertOverlayView() }
                )
                .tag(OnboardingStep.rateApp)
                
                // 5. Notifications
                OnboardingNotificationsPage(
                    imageName: "onboarding_notifications",
                    title: "Don't miss new trends",
                    subtitle: "Allow notifications to stay tuned",
                    onAllow: { handleAllowNotifications() },
                    onMaybeLater: { completeOnboarding() }
                )
                .tag(OnboardingStep.notifications)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()
        }
        .onAppear {
            let savedStep = UserDefaults.standard.integer(forKey: "onboardingCurrentStep")
            if let restored = OnboardingStep(rawValue: savedStep) {
                step = restored
            } else {
                step = .photo
            }
        }
        .onChange(of: step) { newStep in
            UserDefaults.standard.set(newStep.rawValue, forKey: "onboardingCurrentStep")
            appState.onboardingCurrentStep = newStep.rawValue
            
            if newStep == .rateApp {
                RateUsService.requestSystemReview()
            }
        }
    }
    
    // MARK: - Navigation
    
    private func goNext() {
        if let currentIndex = OnboardingStep.allCases.firstIndex(of: step),
           currentIndex + 1 < OnboardingStep.allCases.count {
            withAnimation(.easeInOut) {
                step = OnboardingStep.allCases[currentIndex + 1]
            }
        } else {
            completeOnboarding()
        }
    }
    
    private func handleAllowNotifications() {
        NotificationService.requestPushPermission { _ in
            DispatchQueue.main.async {
                completeOnboarding()
            }
        }
    }
    
    private func completeOnboarding() {
        appState.onboardingCompleted = true
        UserDefaults.standard.set(true, forKey: "onboardingCompleted")
        onFinish()
    }
}
