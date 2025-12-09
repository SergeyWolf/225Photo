//
//  MainTabView.swift
//  225 Photo
//
//  Created by Сергей on 27.11.2025.
//

import SwiftUI

// MARK: - Основной TabBar

enum MainTab: Hashable {
    case home
    case prompt
    case history
    case settings
}

@available(iOS 17.0, *)
struct MainTabView: View {
    @State private var selectedTab: MainTab = .home
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                HomeEffectsView()
            }
            .tabItem {
                VStack {
                    Image("tab_home")
                        .renderingMode(.template)
                    Text("Home")
                }
            }
            .tag(MainTab.home)
            
            NavigationStack {
                if #available(iOS 17.0, *) {
                    PromptView()
                } else { }
            }
            .tabItem {
                VStack {
                    Image("tab_prompt")
                        .renderingMode(.template)
                    Text("Promt")
                }
            }
            .tag(MainTab.prompt)
            
            NavigationStack {
                HistoryView(selectedTab: $selectedTab)
            }
            .tabItem {
                VStack {
                    Image("tab_history")
                        .renderingMode(.template)
                    Text("History")
                }
            }
            .tag(MainTab.history)
            
            NavigationStack {
                SettingsView()
            }
            .tabItem {
                VStack {
                    Image("tab_settings")
                        .renderingMode(.template)
                    Text("Settings")
                }
            }
            .tag(MainTab.settings)
        }
        .tint(Color("OnboardingYellow"))
    }
}

// MARK: - Preview

#Preview {
    if #available(iOS 17.0, *) {
        ContentView()
            .environmentObject(AppState())
    } else { }
}

