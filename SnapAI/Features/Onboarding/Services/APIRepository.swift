//
//  APIRepository.swift
//  SnapAI
//
//  Created by Isa Melsov on 23/9/25.
//

import SwiftUI

//MARK: - APIRepository
// Прод. репозиторий — для бэка (подставишь baseURL и токен)
struct APIRepository: OnboardingRepository {
    let baseURL: URL
    let authToken: String   // JWT из вашего логина; храните в Keychain

    private func request<T: Encodable>(_ path: String, json body: T) async throws {
        var req = URLRequest(url: baseURL.appendingPathComponent(path))
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        req.httpBody = try JSONEncoder().encode(body)

        let (_, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }

    func submitOnboarding(data: OnboardingData) async throws {
        try await request("/onboarding", json: data)          // ← ваш будущий эндпойнт
    }

    func requestAiPersonalPlan(from data: OnboardingData) async throws {
        // через прокси к OpenAI на бэкенде (не с устройства)
        try await request("/ai/personal-plan", json: data)    // ← ваш будущий эндпойнт
    }
}
