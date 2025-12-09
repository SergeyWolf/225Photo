//
//  ContentView.swift
//  225 Photo
//
//  Created by Сергей on 24.11.2025.
//

import SwiftUI

@available(iOS 17.0, *)
struct ContentView: View {
    @EnvironmentObject var appState: AppState

    @State private var showPaywall = false
    @State private var showSplash = true

    var body: some View {
        ZStack {
            mainFlow

            if showSplash {
                SplashScreenView()
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                withAnimation(.easeOut(duration: 0.4)) {
                    showSplash = false
                }
            }
        }
        .onChange(of: appState.onboardingCompleted) { _, completed in
            guard completed else { return }

            if !appState.hasActiveSubscription && !appState.hasShownInitialPaywall {
                appState.hasShownInitialPaywall = true
                UserDefaults.standard.set(true, forKey: "hasShownInitialPaywall")
                showPaywall = true
            }
        }
        .fullScreenCover(isPresented: $showPaywall) {
            SubscriptionPaywallView()
                .environmentObject(appState)
        }
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private var mainFlow: some View {
        if !appState.onboardingCompleted {
            OnboardingFlowView {
                appState.onboardingCompleted = true
                UserDefaults.standard.set(true, forKey: "onboardingCompleted")
            }
        } else {
            MainTabView()
        }
    }
}

#Preview {
    if #available(iOS 17.0, *) {
        ContentView()
            .environmentObject(AppState())
    } else { }
}
