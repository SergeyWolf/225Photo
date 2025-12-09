//
//  HomeNavBar.swift
//  225 Photo
//
//  Created by Сергей on 27.11.2025.
//

import SwiftUI

// MARK: - Навбар Home

struct HomeNavBar: View {
    @EnvironmentObject var appState: AppState

    @State private var showSubscriptionPaywall = false
    @State private var showTokensPaywall = false

    var body: some View {
        HStack {
            MainTabHeader(title: "Home") {
                handleProTap()
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 15)
        .padding(.top, 8)
        .padding(.bottom, 4)
        .background(Color.black)
        .fullScreenCover(isPresented: $showSubscriptionPaywall) {
            SubscriptionPaywallView()
                .environmentObject(appState)
        }
        .fullScreenCover(isPresented: $showTokensPaywall) {
            TokensPaywallView()
                .environmentObject(appState)
        }
    }

    private func handleProTap() {
        if appState.hasActiveSubscription {
            showTokensPaywall = true
        } else {
            showSubscriptionPaywall = true
        }
    }
}
