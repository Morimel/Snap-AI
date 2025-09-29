//
//  OnboardingViewModel.swift
//  SnapAI
//
//  Created by Isa Melsov on 23/9/25.
//

import SwiftUI

// MARK: - ViewModel (фазовая, объединённая)
@MainActor
final class OnboardingViewModel: ObservableObject {
    @Published var data = OnboardingData()
    @Published var phase: OnboardingPhase = .goal
    @Published var personalPlan: PersonalPlan? // для следующего экрана
    @Published var progress: Double = 0.0
    
    private var isFinishing = false

    let repository: OnboardingRepository
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
        guard !isFinishing else { return }
                isFinishing = true
                defer { isFinishing = false }
        
            phase = .submitting
            withAnimation(.easeInOut(duration: 0.2)) { progress = 0.05 }

            // мелкий «тиковый» прогресс на время запроса к ИИ
            var ticker: Task<Void, Never>?

            do {
                // 1) «Сохранение в БД»
                try await repository.submitOnboarding(data: data)
                print("📤 SUBMIT payload:", data.backendPayload()) // ← лог на всякий
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
            } catch {
                ticker?.cancel()
                phase = .failed(error.localizedDescription)
            }
        }
    
    
    func saveManualPlan(calories: Int, proteins: Int, carbs: Int, fats: Int) async {
            do {
                try await AuthAPI.shared.patchPlan(
                    calories: calories, proteinG: proteins, fatG: fats, carbsG: carbs
                )

                // подтягиваем актуальные значения с бэка
                let g = try await AuthAPI.shared.getCurrentPlan()

                // обновляем локальную модель (чтобы PlanScreen перерисовался)
                if let old = self.personalPlan {
                    self.personalPlan = PersonalPlan(
                        weightUnit: old.weightUnit,
                        maintainWeight: old.maintainWeight,
                        dailyCalories: g.dailyCalories,
                        protein: g.proteinG,
                        fat: g.fatG,
                        carbs: g.carbsG,
                        meals: old.meals,
                        workouts: old.workouts
                    )
                } else {
                    self.personalPlan = PersonalPlan(
                        weightUnit: "kg",
                        maintainWeight: 0,
                        dailyCalories: g.dailyCalories,
                        protein: g.proteinG,
                        fat: g.fatG,
                        carbs: g.carbsG,
                        meals: [],
                        workouts: []
                    )
                }
            } catch {
                print("Save manual plan failed:", error.localizedDescription)
            }
        }
}

