//
//  ApidogService.swift
//  225 Photo
//
//  Created by Сергей on 26.11.2025.
//

import Foundation

// MARK: - COMMON ERROR

enum ApidogError: LocalizedError {
    case server(code: String?, message: String?)
    
    var errorDescription: String? {
        switch self {
        case .server(let code, let message):
            let codePart = code.map { "[\($0)] " } ?? ""
            return codePart + (message ?? "Unknown server error")
        }
    }
}

// MARK: - SERVICE

final class ApidogService {
    static let shared = ApidogService()
    private init() {}
    private let authHeader = "Bearer f113066f-2ad6-43eb-b860-8683fde1042a"
    private let scheme = "https"
    private let host = "nextgenwebapps.shop"
    
    // MARK: login
    
    func login(model: ApidogLoginModel) async throws -> ApidogLoginResponse {
        var components = URLComponents()
        components.scheme = scheme
        components.host = host
        components.path = "/api/v1/user/login"
        
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "userId", value: model.userId),
            URLQueryItem(name: "gender", value: model.gender),
            URLQueryItem(name: "source", value: model.source),
            URLQueryItem(name: "payments", value: model.payments)
        ]
        if let fb = model.isFb {
            queryItems.append(URLQueryItem(name: "isFb", value: String(fb)))
        }
        components.queryItems = queryItems
        
        guard let url = components.url else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url, timeoutInterval: 30)
        request.httpMethod = "POST"
        request.addValue(authHeader, forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let raw = String(data: data, encoding: .utf8) {
            print("Apidog login raw response:\n\(raw)")
        }
        
        if let http = response as? HTTPURLResponse,
           !(200...299).contains(http.statusCode) {
            print("Apidog login HTTP error: \(http.statusCode)")
            throw URLError(.badServerResponse)
        }
        
        let decoder = JSONDecoder()
        let result = try decoder.decode(ApidogLoginResponse.self, from: data)
        return result
    }
    
    // MARK: effects/list
    
    func fetchEffectsList(model: ApidogEffectsListModel) async throws -> TemplatesResponse {
        var components = URLComponents()
        components.scheme = scheme
        components.host = host
        components.path = "/api/v1/effects/list"
        
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "lang", value: model.lang),
            URLQueryItem(name: "reels", value: model.reels),
            URLQueryItem(name: "source", value: model.source)
        ]
        if let userId = model.userId {
            queryItems.append(URLQueryItem(name: "userId", value: userId))
        }
        components.queryItems = queryItems
        
        guard let url = components.url else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url, timeoutInterval: 30)
        request.httpMethod = "GET"
        request.addValue(authHeader, forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let raw = String(data: data, encoding: .utf8) {
            print("Apidog effects/list raw response:\n\(raw)")
        }
        
        if let http = response as? HTTPURLResponse,
           !(200...299).contains(http.statusCode) {
            print("Apidog effects/list HTTP error: \(http.statusCode)")
            throw URLError(.badServerResponse)
        }
        
        let decoder = JSONDecoder()
        let raw = try decoder.decode(RawEffectsListResponse.self, from: data)
        
        if raw.error {
            throw ApidogError.server(code: raw.code, message: raw.message)
        }
        
        guard let dataPart = raw.data else {
            throw URLError(.cannotParseResponse)
        }
        
        return TemplatesResponse(
            categories: dataPart.list,
            totalTemplates: dataPart.totalTemplates,
            totalUsed: dataPart.totalUsed
        )
    }
    
    // MARK: effects/generate
    
    /// Отправка фото на генерацию эффекта
    /// - Parameters:
    ///   - templateId: ID эффекта (TemplateEffect.id)
    ///   - imageData: JPEG-картинка, выбранная пользователем
    ///   - source: строка-источник (например, bundle id)
    ///   - userId: ID пользователя (Defaults.userId)
    func generateEffect(
        templateId: Int,
        imageData: Data,
        source: String,
        userId: String?
    ) async throws -> EffectGenerationData {
        
        var components = URLComponents()
        components.scheme = scheme
        components.host = host
        components.path = "/api/v1/effects/generate"
        
        guard let url = components.url else {
            throw URLError(.badURL)
        }
        
        let boundary = "Boundary-\(UUID().uuidString)"
        
        var request = URLRequest(url: url, timeoutInterval: 60)
        request.httpMethod = "POST"
        request.addValue(authHeader, forHTTPHeaderField: "Authorization")
        request.addValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        func appendField(name: String, value: String) {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }
        
        func appendFileField(name: String, filename: String, mimeType: String, fileData: Data) {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
            body.append(fileData)
            body.append("\r\n".data(using: .utf8)!)
        }
        
        // text-поля
        appendField(name: "templateId", value: String(templateId))
        appendField(name: "source", value: source)
        
        if let userId {
            appendField(name: "userId", value: userId)
        }
        
        // file-поле
        appendFileField(
            name: "photo",
            filename: "photo.jpg",
            mimeType: "image/jpeg",
            fileData: imageData
        )
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let raw = String(data: data, encoding: .utf8) {
            print("Apidog effects/generate raw response:\n\(raw)")
        }
        
        if let http = response as? HTTPURLResponse,
           !(200...299).contains(http.statusCode) {
            print("Apidog effects/generate HTTP error: \(http.statusCode)")
            throw URLError(.badServerResponse)
        }
        
        let decoder = JSONDecoder()
        let result = try decoder.decode(EffectGenerationResponse.self, from: data)
        
        if result.error {
            throw ApidogError.server(code: result.code, message: result.message)
        }
        
        guard let info = result.data else {
            throw URLError(.cannotParseResponse)
        }
        
        return info
    }
    
    // MARK: photo/generate/txt2imgBasic
    
    /// Старт текстовой генерации (txt2imgBasic)
    func generateTxt2ImgBasic(
        model: Txt2ImgBasicModel
    ) async throws -> GenerationStatusData {
        var components = URLComponents()
        components.scheme = scheme
        components.host = host
        components.path = "/api/v1/photo/generate/txt2imgBasic"
        
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "userId", value: model.userId),
            URLQueryItem(name: "prompt", value: model.prompt)
        ]
        
        if let templateId = model.templateId {
            queryItems.append(URLQueryItem(name: "templateId", value: String(templateId)))
        }
        
        components.queryItems = queryItems
        
        guard let url = components.url else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url, timeoutInterval: 60)
        request.httpMethod = "POST"
        request.addValue(authHeader, forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let raw = String(data: data, encoding: .utf8) {
            print("Apidog txt2imgBasic raw response:\n\(raw)")
        }
        
        if let http = response as? HTTPURLResponse,
           !(200...299).contains(http.statusCode) {
            print("Apidog txt2imgBasic HTTP error: \(http.statusCode)")
            throw URLError(.badServerResponse)
        }
        
        let decoder = JSONDecoder()
        let result = try decoder.decode(GenerationStatusResponse.self, from: data)
        
        if result.error {
            throw ApidogError.server(code: nil, message: result.message)
        }
        
        guard let info = result.data else {
            throw URLError(.cannotParseResponse)
        }
        
        return info
    }
    
    // MARK: services/status
    
    /// Проверка статуса генерации по jobId
    func getGenerationStatus(
        jobId: String,
        userId: String
    ) async throws -> GenerationStatusData {
        var components = URLComponents()
        components.scheme = scheme
        components.host = host
        components.path = "/api/v1/services/status"
        components.queryItems = [
            URLQueryItem(name: "userId", value: userId),
            URLQueryItem(name: "jobId", value: jobId)
        ]
        
        guard let url = components.url else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url, timeoutInterval: 30)
        request.httpMethod = "GET"
        request.addValue(authHeader, forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let raw = String(data: data, encoding: .utf8) {
            print("Apidog services/status raw response:\n\(raw)")
        }
        
        if let http = response as? HTTPURLResponse,
           !(200...299).contains(http.statusCode) {
            print("Apidog services/status HTTP error: \(http.statusCode)")
            throw URLError(.badServerResponse)
        }
        
        let decoder = JSONDecoder()
        let result = try decoder.decode(GenerationStatusResponse.self, from: data)
        
        if result.error {
            throw ApidogError.server(code: nil, message: result.message)
        }
        
        guard let info = result.data else {
            throw URLError(.cannotParseResponse)
        }
        
        return info
    }
}

