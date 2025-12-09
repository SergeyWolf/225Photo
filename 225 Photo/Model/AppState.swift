//
//  AppState.swift
//  225 Photo
//
//  Created by Сергей on 24.11.2025.
//

import Foundation

final class AppState: ObservableObject {
    // MARK: - Onboarding

    @Published var onboardingCompleted: Bool
    @Published var onboardingCurrentStep: Int

    // MARK: - Подписка / paywall

    /// Есть ли активная подписка (заполняется после Apphud purchase/restore)
    @Published var hasActiveSubscription: Bool = false

    /// Показан ли уже paywall сразу после онбординга (чтобы не показывать повторно)
    @Published var hasShownInitialPaywall: Bool

    // MARK: - Токены (на будущее)

    @Published var tokensBalance: Int {
        didSet {
            Defaults.tokensBalance = tokensBalance
        }
    }

    // MARK: - Эффекты и статистика пользователя (кэш с Home)

    @Published var templatesResponse: TemplatesResponse?
    @Published var userStat: ApidogStat?

    // MARK: - История генераций (вкладка History)

    @Published var generationHistory: [GenerationHistoryItem] = []

    // MARK: - Init

    init() {
        // онбординг как и раньше
        onboardingCompleted = UserDefaults.standard.bool(forKey: "onboardingCompleted")
        onboardingCurrentStep = UserDefaults.standard.integer(forKey: "onboardingCurrentStep")
        hasShownInitialPaywall = UserDefaults.standard.bool(forKey: "hasShownInitialPaywall")
        self.tokensBalance = Defaults.tokensBalance

        // история — через Defaults обёртку
        generationHistory = Defaults.generationHistory
        prefetchHistoryImages()
    }

    // MARK: - History API

    /// Добавить новую генерацию (новые — сверху)
    func addHistoryItem(_ item: GenerationHistoryItem) {
        generationHistory.insert(item, at: 0)
        saveHistory()
        prefetchHistoryImages()
    }

    /// Обновить запись по jobId (например, после /services/status)
    func updateHistoryItem(jobId: String, with statusData: GenerationStatusData) {
        guard let index = generationHistory.firstIndex(where: { $0.jobId == jobId }) else { return }

        generationHistory[index].applyStatus(statusData)
        saveHistory()
        prefetchHistoryImages()
    }

    /// Пометить генерацию как ошибочную
    func markHistoryError(jobId: String, message: String?) {
        guard let index = generationHistory.firstIndex(where: { $0.jobId == jobId }) else { return }

        generationHistory[index].status = .error
        generationHistory[index].errorMessage = message
        saveHistory()
    }

    /// Удалить генерацию по её UUID (используется из History/GenerationResultView)
    func deleteHistoryItem(id: UUID) {
        generationHistory.removeAll { $0.id == id }
        saveHistory()
        prefetchHistoryImages()
    }

    /// Полностью очистить историю (для Clear cache в настройках)
    func clearHistory() {
        generationHistory.removeAll()
        saveHistory()
        prefetchHistoryImages()
    }

    // MARK: - Persistence через Defaults

    private func saveHistory() {
        Defaults.generationHistory = generationHistory
    }

    // MARK: - Prefetch изображений

    /// Префетчим все изображения из истории (preview/result), чтобы они
    /// загружались асинхронно, независимо от того, показана ячейка или нет.
    private func prefetchHistoryImages() {
        let urls = generationHistory.compactMap { $0.resultURL ?? $0.previewURL }
        ImageLoader.shared.prefetch(urls: urls)
    }
}

