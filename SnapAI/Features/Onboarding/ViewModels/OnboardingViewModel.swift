//
//  OnboardingViewModel.swift
//  SnapAI
//
//  Created by Isa Melsov on 23/9/25.
//

import SwiftUI

// MARK: - ViewModel 
@MainActor
final class OnboardingViewModel: ObservableObject {
    @Published var data = OnboardingData()
    @Published var phase: OnboardingPhase = .goal
    @Published var personalPlan: PersonalPlan?
    @Published var progress: Double = 0.0
    
    private var isFinishing = false

    let repository: OnboardingRepository
    private let onFinished: () -> Void

    init(repository: OnboardingRepository, onFinished: @escaping () -> Void) {
        self.repository = repository
        self.onFinished = onFinished
    }

    func saveDraft() {
        Task { try? await repository.submitOnboarding(data: data) }
    }

    func finish() async {
        guard !isFinishing else { return }
                isFinishing = true
                defer { isFinishing = false }
        
            phase = .submitting
            withAnimation(.easeInOut(duration: 0.2)) { progress = 0.05 }

            var ticker: Task<Void, Never>?

            do {
                try await repository.submitOnboarding(data: data)
                print("📤 SUBMIT payload:", data.backendPayload())
                withAnimation(.easeInOut(duration: 0.25)) { progress = 0.35 }

                ticker = Task { @MainActor in
                    while !Task.isCancelled && progress < 0.9 {
                        try? await Task.sleep(nanoseconds: 50_000_000)
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

                let g = try await AuthAPI.shared.getCurrentPlan()

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

