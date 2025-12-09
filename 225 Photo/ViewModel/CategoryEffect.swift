//
//  CategoryEffect.swift
//  225 Photo
//
//  Created by Сергей on 05.12.2025.
//

// MARK: - MODELS: CATEGORY & EFFECT
struct TemplateCategory: Identifiable, Decodable {
    let id: Int
    let title: String
    let categoryDescription: String?
    let preview: String?
    let isNew: Bool
    let totalEffects: Int
    let totalUsed: Int
    let effects: [TemplateEffect]
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case categoryDescription = "description"
        case preview
        case isNew
        case totalEffects
        case totalUsed
        case effects
    }
}

struct TemplateEffect: Identifiable, Decodable {
    let id: Int
    let title: String
    let preview: String?
    let previewProduction: String?
    let previewBefore: String?
    let gender: String?
    let prompt: String?
    let isEnabled: Bool
}
