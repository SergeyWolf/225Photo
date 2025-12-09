//
//  Basic.swift
//  225 Photo
//
//  Created by Сергей on 05.12.2025.
//

// MARK: - TXT2IMG BASIC

/// Модель запроса для /photo/generate/txt2imgBasic
struct Txt2ImgBasicModel {
    /// промпт
    let prompt: String
    /// optional templateId
    let templateId: Int?
    /// userId
    let userId: String
}
