//
//  EffectsList.swift
//  225 Photo
//
//  Created by Сергей on 05.12.2025.
//

// MARK: - EFFECTS LIST
struct ApidogEffectsListModel {
    let lang: String
    let reels: String
    let source: String
    let userId: String?
}

struct TemplatesResponse: Decodable {
    let categories: [TemplateCategory]
    let totalTemplates: Int
    let totalUsed: Int
}

struct RawEffectsListResponse: Decodable {
    let error: Bool
    let code: String?
    let message: String?
    let data: RawEffectsListData?
}

struct RawEffectsListData: Decodable {
    let list: [TemplateCategory]
    let totalTemplates: Int
    let totalUsed: Int
}
