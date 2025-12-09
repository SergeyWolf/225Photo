//
//  HistoryView.swift
//  225 Photo
//
//  Created by Сергей on 05.12.2025.
//

//import SwiftUICore
import SwiftUI

@available(iOS 17.0, *)
struct HistoryView: View {
    @EnvironmentObject var appState: AppState

    @Binding var selectedTab: MainTab
    @State private var selectedItem: GenerationHistoryItem?
    @State private var showDeleteAlert = false
    @State private var itemPendingDeletion: GenerationHistoryItem?
    @State private var showResult = false
    @State private var currentResultItem: GenerationHistoryItem?
    @State private var showPaywall = false

    private let gridColumns = Array(
        repeating: GridItem(.fixed(116), spacing: 20),
        count: 3
    )

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if appState.generationHistory.isEmpty {
                emptyState
            } else {
                VStack(spacing: 0) {
                    header

                    ScrollView(showsIndicators: false) {
                        LazyVGrid(columns: gridColumns, spacing: 10) {
                            ForEach(appState.generationHistory) { item in
                                HistoryCardView(
                                    item: item,
                                    onTap: {
                                        handleTap(on: item)
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.top, 16)
                        .padding(.bottom, 24)
                    }
                }
                .padding(.top, 16)
            }
        }
        .navigationBarHidden(true)
        .sheet(item: $selectedItem) { item in
            HistoryErrorSheet(
                item: item,
                onRefresh: {
                    selectedItem = nil
                    refreshStatus(for: item)
                },
                onDelete: {
                    itemPendingDeletion = item
                    selectedItem = nil
                    showDeleteAlert = true
                },
                onCancel: {
                    selectedItem = nil
                }
            )
            .presentationDetents([.height(320)])
            .presentationDragIndicator(.hidden)
            .presentationBackground(.clear)
        }
        .alert(
            "Delete the generation?",
            isPresented: $showDeleteAlert,
            presenting: itemPendingDeletion
        ) { item in
            Button("Cancel", role: .cancel) {
                itemPendingDeletion = nil
            }
            Button("Delete", role: .destructive) {
                appState.deleteHistoryItem(id: item.id)
                itemPendingDeletion = nil
            }
        } message: { _ in
            Text("You will not be able to restore it after deletion.")
        }
        .background(
            NavigationLink(
                destination: resultDestination,
                isActive: $showResult,
                label: { EmptyView() }
            )
            .hidden()
        )
    }

    // MARK: - Subviews

    private var header: some View {
        HStack {
            MainTabHeader(title: "History") {
                showPaywall = true
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 15)
        .fullScreenCover(isPresented: $showPaywall) {
            if appState.hasActiveSubscription {
                TokensPaywallView()
            } else {
                SubscriptionPaywallView()
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 24) {
            header

            Spacer()

            VStack(spacing: 12) {
                Text("No generations")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)

                Text("Create your first generation using effects or a text query")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Button {
                    selectedTab = .home
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 17, weight: .semibold))
                        Text("Create")
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(minHeight: 52)
                    .frame(maxWidth: 220)
                    .background(Color("OnboardingYellow"))
                    .cornerRadius(16)
                }
            }

            Spacer()
        }
    }

    // MARK: - Actions

    private func handleTap(on item: GenerationHistoryItem) {
        switch item.status {
        case .success:
            guard item.resultURL != nil else { return }
            currentResultItem = item
            showResult = true

        case .inProgress, .error:
            selectedItem = item
        }
    }

    /// Refresh из Select action:
    /// 1) единоразово дергаем getGenerationStatus, сразу обновляем карточку;
    /// 2) всегда запускаем polling через GenerationManager — он сам выйдет, если статус уже финальный.
    private func refreshStatus(for item: GenerationHistoryItem) {
        Task {
            let userId = Defaults.userId

            do {
                // 1) моментальный статус
                let status = try await ApidogService.shared.getGenerationStatus(
                    jobId: item.jobId,
                    userId: userId
                )

                let resultLog = status.resultUrl ?? "nil"

                await MainActor.run {
                    appState.updateHistoryItem(jobId: item.jobId, with: status)
                }

                Task.detached {
                    do {
                        try await GenerationManager.shared.resumeTracking(
                            jobId: item.jobId,
                            appState: appState
                        )
                    } catch {
                        print("Failed to resume tracking for jobId \(item.jobId): \(error)")
                    }
                }
            } catch {
                print("Failed to refresh status for jobId \(item.jobId): \(error)")
                await MainActor.run {
                    appState.markHistoryError(
                        jobId: item.jobId,
                        message: error.localizedDescription
                    )
                }
            }
        }
    }

    // MARK: - Result destination

    @ViewBuilder
    private var resultDestination: some View {
        if let item = currentResultItem,
           let url = item.resultURL {
            GenerationResultView(
                imageURL: url,
                title: item.title,
                prompt: item.prompt,
                onDelete: {
                    appState.deleteHistoryItem(id: item.id)
                }
            )
        } else {
            EmptyView()
        }
    }
}

