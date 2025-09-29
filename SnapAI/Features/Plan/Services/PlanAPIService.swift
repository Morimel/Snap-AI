//
//  PlanAPIService.swift
//  SnapAI
//
//  Created by Isa Melsov on 27/9/25.
//

// Что возвращает generate-plan (имена ключей гибкие)
private struct GeneratePlanResponse: Decodable {
    let dailyCalories: Int
    let proteinG: Int
    let fatG: Int
    let carbsG: Int

    enum CodingKeys: String, CodingKey {
        case daily_calories, daily_kcal, calories
        case protein_g, protein
        case fat_g, fat
        case carbs_g, carbs
    }

    init(from d: Decoder) throws {
        let c = try d.container(keyedBy: CodingKeys.self)
        // калории
        if let v = try c.decodeIfPresent(Int.self, forKey: .daily_calories) {
            dailyCalories = v
        } else if let v = try c.decodeIfPresent(Int.self, forKey: .daily_kcal) {
            dailyCalories = v
        } else if let v = try c.decodeIfPresent(Int.self, forKey: .calories) {
            dailyCalories = v
        } else {
            throw DecodingError.dataCorrupted(.init(codingPath: c.codingPath, debugDescription: "No calories"))
        }
        // белки
        proteinG = try c.decodeIfPresent(Int.self, forKey: .protein_g)
                ?? c.decode(Int.self, forKey: .protein)
        // жиры
        fatG     = try c.decodeIfPresent(Int.self, forKey: .fat_g)
                ?? c.decode(Int.self, forKey: .fat)
        // угли
        carbsG   = try c.decodeIfPresent(Int.self, forKey: .carbs_g)
                ?? c.decode(Int.self, forKey: .carbs)
    }
}

private struct EmptyResponse: Decodable {}

extension AuthAPI {
    // уже есть:
    // func submitOnboarding(_ data: OnboardingData) ...

    // POST /api/profile/generate-plan/ → калории/БЖУ
    func generatePlan() async throws -> GeneratePlanResponse {
        try await post("api/profile/generate-plan/", [:])
    }
}
