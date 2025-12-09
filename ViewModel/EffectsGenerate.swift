//
//  EffectsGenerate.swift
//  225 Photo
//
//  Created by Сергей on 05.12.2025.
//

// MARK: - EFFECTS GENERATE
struct EffectGenerationResponse: Decodable {
    let error: Bool
    let code: String?
    let message: String?
    let data: EffectGenerationData?
}

struct EffectGenerationData: Decodable {
    let id: Int
    let generationId: Int
    let jobId: String
    let templateId: Int
    let preview: String?
    let resultUrl: String?
    let status: String
    let errorCode: String?
    let generationType: String
    let generationTypeId: Int
    let prompt: String?
    let isGodMode: Bool
    let isCouplePhoto: Bool
    let isPV: Bool
    let isPika: Bool
    let isTxt2Img: Bool
    let isMarked: Bool
    let audioUrl: String?
    let mark: Int?
    let seconds: Int
    let startedAt: String?
    let finishedAt: String?
}
