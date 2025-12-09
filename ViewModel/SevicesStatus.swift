//
//  SevicesStatus.swift
//  225 Photo
//
//  Created by Сергей on 05.12.2025.
//

// MARK: - SERVICES STATUS
struct GenerationStatusResponse: Decodable {
    let error: Bool
    let message: String?
    let data: GenerationStatusData?
}

struct GenerationStatusData: Decodable {
    let id: Int
    let generationId: Int
    let jobId: String
    let templateId: Int?
    let preview: String?
    let resultUrl: String?
    let status: String
    let isGodMode: Bool
    let isCouplePhoto: Bool
    let isPV: Bool
    let isPika: Bool
    let isTxt2Img: Bool
    let isMarked: Bool
    let mark: Int?
    let seconds: Int
    let startedAt: String?
    let finishedAt: String?
}
