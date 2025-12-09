//
//  GenerationManager.swift
//  225 Photo
//
//  Общий менеджер генераций для эффектов и промптов.
//  Отвечает за запросы к API, polling статуса и обновление History.
//

import Foundation
import UIKit

final class GenerationManager {

    static let shared = GenerationManager()
    private init() {}

    // MARK: - Result

    struct Result {
        /// jobId задачи на бекенде
        let jobId: String
        /// URL итогового изображения (если удалось получить)
        let imageURL: URL?
        /// Финальный статус задачи
        let status: GenerationStatusData
    }

    // MARK: - Генерация по фото (effects/generate)

    func generateWithPhoto(
        image: UIImage,
        effect: TemplateEffect,
        appState: AppState
    ) async throws -> Result {

        guard let jpegData = image.jpegData(compressionQuality: 0.9) else {
            throw NSError(
                domain: "GenerationManager",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Failed to prepare photo for generation."]
            )
        }

        let templateId = effect.id
        let source = Bundle.main.bundleIdentifier ?? "225photo"
        let userId = Defaults.userId
        let jpegSize = jpegData.count
        let imageSize = image.size

        var startedJobId: String?

        do {
            // 1) Старт генерации по фото
            let generationData = try await ApidogService.shared.generateEffect(
                templateId: templateId,
                imageData: jpegData,
                source: source,
                userId: userId
            )
            

            startedJobId = generationData.jobId
            

            // 1.1) Добавляем запись в историю
            await MainActor.run {
                let item = GenerationHistoryItem(effect: effect, generation: generationData)
                appState.addHistoryItem(item)
            }

            // 2) Пуллим статус (обрабатываем и IN_PROGRESS, и NEW внутри pollStatus)
            let finalStatus = try await pollStatus(jobId: generationData.jobId, userId: userId)

            // 2.1) Обновляем History
            await MainActor.run {
                appState.updateHistoryItem(jobId: generationData.jobId, with: finalStatus)
            }

            let url = finalStatus.resultUrl.flatMap(URL.init(string:))

            // 3.1) Пуш при успешной генерации (если есть результат)
            if url != nil {
                NotificationService.scheduleGenerationFinishedNotification(
                    title: "Effect ready",
                    body: "Your \"\(effect.title)\" photo has been generated."
                )

                // 3.2) После успешной генерации обновляем токены с сервера
                await refreshUserTokens(appState: appState)
            }

            return Result(jobId: generationData.jobId, imageURL: url, status: finalStatus)

        } catch {
            let message = error.localizedDescription.isEmpty
            ? "Something went wrong or the server is not responding. Try again or do it later."
            : error.localizedDescription

            if let jobId = startedJobId {
                await MainActor.run {
                    appState.markHistoryError(jobId: jobId, message: message)
                }
            }

            throw error
        }
    }

    // MARK: - Генерация по тексту (txt2imgBasic)

    /// Старт текстовой генерации.
    /// Если пользователь выбрал стиль, в API уходит промпт с первой строкой:
    ///   "Style: <название стиля>"
    /// но в историю и UI сохраняется чистый промпт пользователя.
    func generateWithPrompt(
        prompt: String,
        styleEffect: TemplateEffect?,
        appState: AppState
    ) async throws -> Result {

        let userId = Defaults.userId
        let promptForApi: String
        if let style = styleEffect {
            promptForApi = "Style: \(style.title)\n\(prompt)"
        } else {
            promptForApi = prompt
        }

        let model = Txt2ImgBasicModel(
            prompt: promptForApi,
            templateId: nil,
            userId: userId
        )

        let templateIdLog = (styleEffect?.id).map { String($0) } ?? "nil"
        let styleTitleLog = styleEffect?.title ?? "nil"
        var startedJobId: String?

        do {
            // 1) Старт текстовой генерации
            let initialStatus = try await ApidogService.shared.generateTxt2ImgBasic(
                model: model
            )

            startedJobId = initialStatus.jobId

            // 1.1) Записываем в History с исходным статусом (NEW или IN_PROGRESS)
            await MainActor.run {
                let item = GenerationHistoryItem(
                    prompt: prompt,          // в историю кладём чистый промпт пользователя
                    styleEffect: styleEffect,
                    statusData: initialStatus
                )
                appState.addHistoryItem(item)
            }

            // 2) Если задача ещё не завершена (IN_PROGRESS или NEW) — начинаем polling
            let finalStatus: GenerationStatusData
            if initialStatus.status == "IN_PROGRESS" || initialStatus.status == "NEW" {
                finalStatus = try await pollStatus(jobId: initialStatus.jobId, userId: userId)
            } else {
                // если вдруг сразу вернулся финальный статус (DONE / FAILED / и т.п.)
                finalStatus = initialStatus
            }

            // 2.1) Обновляем History
            await MainActor.run {
                appState.updateHistoryItem(jobId: initialStatus.jobId, with: finalStatus)
            }

            let url = finalStatus.resultUrl.flatMap(URL.init(string:))

            // 2.2) Пуш при успешной генерации (если есть результат)
            if url != nil {
                let title = styleEffect?.title ?? "Prompt generation"
                NotificationService.scheduleGenerationFinishedNotification(
                    title: "Generation ready",
                    body: "Your \"\(title)\" image has been generated."
                )

                // 2.3) После успешной генерации обновляем токены с сервера
                await refreshUserTokens(appState: appState)
            }

            return Result(jobId: initialStatus.jobId, imageURL: url, status: finalStatus)

        } catch {
            let message = error.localizedDescription.isEmpty
            ? "Something went wrong or the server is not responding. Try again or do it later."
            : error.localizedDescription

            if let jobId = startedJobId {
                await MainActor.run {
                    appState.markHistoryError(jobId: jobId, message: message)
                }
            }

            throw error
        }
    }
    
    /// После успешной генерации подтягиваем актуальные токены с сервера.
    private func refreshUserTokens(appState: AppState) async {
        let loginModel = ApidogLoginModel(
            gender: "m",
            isFb: nil,
            payments: "1",
            source: AppConstants.Bundle.bundle,
            userId: Defaults.userId
        )

        do {
            let loginResponse = try await ApidogService.shared.login(model: loginModel)
            let stat = loginResponse.data?.stat

            await MainActor.run {
                appState.userStat = stat
                if let available = stat?.availableGenerations {
                    appState.tokensBalance = available
                }
            }
        } catch {
            print("Apidog login (refresh tokens) failed: \(error)")
        }
    }

    // MARK: - Возобновление отслеживания существующей задачи (History → Refresh)

    /// Используется, когда пользователь нажимает Refresh в History.
    /// Предполагается, что задача уже существует на сервере, а мы просто снова начинаем polling.
    func resumeTracking(
        jobId: String,
        appState: AppState,
        interval: TimeInterval = 8,
        maxAttempts: Int = 30
    ) async throws {

        let userId = Defaults.userId

        do {
            let finalStatus = try await pollStatus(
                jobId: jobId,
                userId: userId,
                interval: interval,
                maxAttempts: maxAttempts
            )

            await MainActor.run {
                appState.updateHistoryItem(jobId: jobId, with: finalStatus)
            }

            if finalStatus.resultUrl != nil {
                await refreshUserTokens(appState: appState)
            }
        } catch {
            let message = error.localizedDescription.isEmpty
            ? "Something went wrong or the server is not responding. Try again or do it later."
            : error.localizedDescription

            await MainActor.run {
                appState.markHistoryError(jobId: jobId, message: message)
            }

            throw error
        }
    }

    // MARK: - Общий polling статуса

    private func pollStatus(
        jobId: String,
        userId: String,
        interval: TimeInterval = 8,
        maxAttempts: Int = 30
    ) async throws -> GenerationStatusData {

        for attempt in 1...maxAttempts {
            let status = try await ApidogService.shared.getGenerationStatus(
                jobId: jobId,
                userId: userId
            )

            print("📡 Poll \(attempt): status = \(status.status)")

            if status.status != "IN_PROGRESS" && status.status != "NEW" {
                return status
            }

            try await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
        }

        throw NSError(
            domain: "GenerationManager",
            code: -1,
            userInfo: [NSLocalizedDescriptionKey: "Timeout while waiting for generation"]
        )
    }
}

