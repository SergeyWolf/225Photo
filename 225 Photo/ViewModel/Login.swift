//
//  Login.swift
//  225 Photo
//
//  Created by Сергей on 05.12.2025.
//

// MARK: - LOGIN
struct ApidogLoginModel {
    let gender: String
    let isFb: Int?
    let payments: String
    let source: String
    let userId: String
}

struct ApidogLoginResponse: Decodable {
    let error: Bool
    let code: String?
    let message: String?
    let data: ApidogUserData?
}

struct ApidogUserData: Decodable {
    let id: Int
    let userId: String

    let startAt: String?
    let endAt: String?
    let activePlanId: Int?
    let planTokens: Int?
    let isActivePlan: Bool?
    let isActiveSubscription: Bool?
    let planInfo: ApidogPlanInfo?

    let gender: String
    let source: String
    let isNewRegistered: Bool
    let stat: ApidogStat
    let avatars: [ApidogAvatar]
}

struct ApidogPlanInfo: Decodable {
    let id: Int
    let code: String?
    let title: String?
    let productId: String?
    let maxPhotos: Int?
    let maxAvatars: Int?
    let price: Int?
    let oldPrice: Int?
    let isForSubscription: Bool?
    let isForOption: Bool?
    let isForAvatar: Bool?
}

struct ApidogStat: Decodable {
    let startAt: String?

    let maxPhotos: Int?
    let maxStyles: Int?
    let maxModels: Int?
    let isActiveTariff: Bool?
    let tariffId: Int?

    let maxUploadPhotos: Int?
    let minUploadPhotos: Int?

    let totalGenerations: Int?
    let totalGenerationsTemplate: Int?
    let totalGenerationsGod: Int?

    let totalModels: Int?
    let availableModels: Int?
    let availableGenerations: Int?
}

struct ApidogAvatar: Decodable {}
