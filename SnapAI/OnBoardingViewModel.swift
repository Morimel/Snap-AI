//
//  OnBoardingViewMode;.swift
//  SnapAI
//
//  Created by Isa Melsov on 16/9/25.
//

import Foundation
import SwiftUI

// MARK: - Навигационный контейнер

struct AppNavigationContainer<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        if #available(iOS 16.0, *) {
            NavigationStack { content() }
        } else {
            NavigationView { content() }
                .navigationViewStyle(StackNavigationViewStyle())
        }
    }
}

// MARK: - Модель плана (минимум для компиляции)
// Если у тебя уже есть свой PersonalPlan — удали эту секцию.
struct PersonalPlan: Codable, Equatable {
    struct Meal: Codable, Equatable { let time: String; let title: String; let kcal: Int }
    struct Workout: Codable, Equatable { let day: String; let focus: String; let durationMin: Int }
    let weightUnit: String
    let maintainWeight: Int
    let dailyCalories: Int
    let protein: Int
    let fat: Int
    let carbs: Int
    let meals: [Meal]
    let workouts: [Workout]
}

// MARK: - Этапы онбординга

enum OnboardingPhase: Equatable {
    case goal       // экран выбора цели
    case rate       // экран Rate
    case submitting // показываем крутилку и шлём данные
    case ready      // получили план — идём на «экран два»
    case failed(String)
}

// MARK: - Репозиторий

protocol OnboardingRepository {
    func submitOnboarding(data: OnboardingData) async throws
    func requestAiPersonalPlan(from data: OnboardingData) async throws
    /// Опционально: если репозиторий что-то сохранил локально — вернём план.
    func fetchSavedPlan() -> PersonalPlan?
}

extension OnboardingRepository {
    func fetchSavedPlan() -> PersonalPlan? { nil }
}

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

// Локальный репозиторий — для работы без бэка (моки/семплы). Можно удалить, если не нужен.
final class LocalRepository: OnboardingRepository {
    private let planKey = "snapai.personalPlan.v1"
    private let onboardingKey = "snapai.onboarding.v1"

    func submitOnboarding(data: OnboardingData) async throws {
        let enc = JSONEncoder(); enc.dateEncodingStrategy = .iso8601
        let blob = try enc.encode(data)
        UserDefaults.standard.set(blob, forKey: onboardingKey)
    }

    func requestAiPersonalPlan(from data: OnboardingData) async throws {
        // эмуляция «запроса в ChatGPT» (задержка + генерация семпла)
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

// MARK: - ViewModel (фазовая, объединённая)

@MainActor
final class OnboardingViewModel: ObservableObject {
    @Published var data = OnboardingData()
    @Published var phase: OnboardingPhase = .goal
    @Published var personalPlan: PersonalPlan? // для следующего экрана
    @Published var progress: Double = 0.0

    private let repository: OnboardingRepository
    private let onFinished: () -> Void

    init(repository: OnboardingRepository, onFinished: @escaping () -> Void) {
        self.repository = repository
        self.onFinished = onFinished
    }

    /// Сохранение черновика — безопасно вызывает submit в фоне.
    func saveDraft() {
        Task { try? await repository.submitOnboarding(data: data) }
    }

    /// Единая финализация: сохранить + запросить план
    func finish() async {
            phase = .submitting
            withAnimation(.easeInOut(duration: 0.2)) { progress = 0.05 }

            // мелкий «тиковый» прогресс на время запроса к ИИ
            var ticker: Task<Void, Never>?

            do {
                // 1) «Сохранение в БД»
                try await repository.submitOnboarding(data: data)
                withAnimation(.easeInOut(duration: 0.25)) { progress = 0.35 }

                // 2) «Запрос в ChatGPT» (+ ожидание ответа)
                // пока ждём — плавно подрасти до ~0.9, чтобы ощущалось «живым»
                ticker = Task { @MainActor in
                    while !Task.isCancelled && progress < 0.9 {
                        try? await Task.sleep(nanoseconds: 50_000_000) // 0.05s
                        progress = min(progress + 0.02, 0.9)
                    }
                }

                try await repository.requestAiPersonalPlan(from: data)
                ticker?.cancel()

                personalPlan = repository.fetchSavedPlan()
                withAnimation(.easeInOut(duration: 0.25)) { progress = 1.0 }

                phase = .ready
                onFinished() // если после онбординга переключаешь root на PlanHostView
            } catch {
                ticker?.cancel()
                phase = .failed(error.localizedDescription)
            }
        }
}
