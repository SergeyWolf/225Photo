//
//  GenerationHistoryItem.swift
//  225 Photo
//
//  Created by Sergey on 05.12.2025.
//

import Foundation

enum HistoryGenerationStatus: String, Codable {
    case inProgress
    case success
    case error
}

struct GenerationHistoryItem: Identifiable, Codable {
    let id: UUID

    /// jobId из бекенда — по нему пулим статус
    let jobId: String

    /// Заголовок эффекта / стиля / генерации
    let title: String

    /// Когда запустили генерацию
    let createdAt: Date

    /// Превью (до / во время генерации)
    var previewURL: URL?

    /// Финальный результат
    var resultURL: URL?

    /// Текущий статус
    var status: HistoryGenerationStatus

    /// Текст ошибки для Read more
    var errorMessage: String?

    /// Текст промпта (только для текстовых генераций)
    var prompt: String?

    // MARK: - Инициализация: генерация по фото (effects/generate)

    init(effect: TemplateEffect, generation: EffectGenerationData) {
        self.id = UUID()
        self.jobId = generation.jobId
        self.title = effect.title
        self.createdAt = Date()

        let previewString =
            generation.preview ??
            effect.previewBefore ??
            effect.previewProduction ??
            effect.preview

        if let previewString,
           let url = URL(string: previewString) {
            self.previewURL = url
        } else {
            self.previewURL = nil
        }

        if let result = generation.resultUrl,
           let url = URL(string: result) {
            self.resultURL = url
        } else {
            self.resultURL = nil
        }

        switch generation.status {
        case "IN_PROGRESS", "NEW":
            self.status = .inProgress
        default:
            if generation.resultUrl != nil {
                self.status = .success
            } else {
                self.status = .error
            }
        }

        self.errorMessage = nil
        self.prompt = nil
    }

    // MARK: - Инициализация: текстовая генерация (txt2imgBasic)

    init(prompt: String, styleEffect: TemplateEffect?, statusData: GenerationStatusData) {
        self.id = UUID()
        self.jobId = statusData.jobId
        self.title = styleEffect?.title ?? "Prompt"
        self.createdAt = Date()

        if let preview = statusData.preview,
           let url = URL(string: preview) {
            self.previewURL = url
        } else {
            self.previewURL = nil
        }

        if let result = statusData.resultUrl,
           let url = URL(string: result) {
            self.resultURL = url
        } else {
            self.resultURL = nil
        }

        switch statusData.status {
        case "IN_PROGRESS", "NEW":
            self.status = .inProgress
        case "ERROR":
            self.status = .error
        default:
            self.status = statusData.resultUrl == nil ? .error : .success
        }

        self.errorMessage = nil
        self.prompt = prompt
    }

    // MARK: - Обновление по статусу /services/status

    mutating func applyStatus(_ statusData: GenerationStatusData) {
        if let preview = statusData.preview,
           let url = URL(string: preview) {
            self.previewURL = url
        }
        if let result = statusData.resultUrl,
           let url = URL(string: result) {
            self.resultURL = url
        }

        switch statusData.status {
        case "IN_PROGRESS", "NEW":
            self.status = .inProgress
        case "ERROR":
            self.status = .error
        default:
            self.status = statusData.resultUrl == nil ? .error : .success
        }

        if case .success = self.status {
            self.errorMessage = nil
        }
    }
}

