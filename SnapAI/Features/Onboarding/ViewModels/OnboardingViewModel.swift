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

