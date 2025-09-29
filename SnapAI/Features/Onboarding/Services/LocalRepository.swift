//
//  LocalRepository.swift
//  SnapAI
//
//  Created by Isa Melsov on 23/9/25.
//

import SwiftUI

//MARK: - LocalRepository
final class LocalRepository: OnboardingRepository {
    private let planKey = "snapai.personalPlan.v1"
    private let onboardingKey = "snapai.onboarding.v1"

    func submitOnboarding(data: OnboardingData) async throws {
        let enc = JSONEncoder(); enc.dateEncodingStrategy = .iso8601
        let blob = try enc.encode(data)
        UserDefaults.standard.set(blob, forKey: onboardingKey)
    }

    func requestAiPersonalPlan(from data: OnboardingData) async throws {
        try await Task.sleep(nanoseconds: 1_000_000_000)
        let base = 2200
        let delta = (data.goal == .lose ? -300 : data.goal == .gain ? +300 : 0)
        let daily = max(1200, base + delta)

        let sample = PersonalPlan(
            weightUnit: "lbs",
            maintainWeight: 121,
            dailyCalories: daily,
            protein: 140,
            fat: 70,
            carbs: max(0, (daily - 140*4 - 70*9) / 4),
            meals: [
                .init(time: "08:30", title: "Овсянка с ягодами", kcal: 420),
                .init(time: "13:00", title: "Курица + рис + салат", kcal: 620),
                .init(time: "17:00", title: "Творог + яблоко", kcal: 280),
                .init(time: "20:00", title: "Лосось + гречка + овощи", kcal: 620),
            ],
            workouts: [
                .init(day: "Пн", focus: "Грудь/трицепс", durationMin: 45),
                .init(day: "Ср", focus: "Спина/бицепс", durationMin: 45),
                .init(day: "Пт", focus: "Ноги/кор", durationMin: 50),
            ]
        )

        let blob = try JSONEncoder().encode(sample)
        UserDefaults.standard.set(blob, forKey: planKey)
    }

    func fetchSavedPlan() -> PersonalPlan? {
        guard let blob = UserDefaults.standard.data(forKey: planKey) else { return nil }
        return try? JSONDecoder().decode(PersonalPlan.self, from: blob)
    }
}
