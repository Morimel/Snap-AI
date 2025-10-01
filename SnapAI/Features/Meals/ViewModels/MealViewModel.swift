//
//  MealViewModel.swift
//  SnapAI
//
//  Created by Isa Melsov on 23/9/25.
//

import SwiftUI

//MARK: - MealViewModel
@MainActor
final class MealViewModel: ObservableObject {
    @Published var meal = Meal()
    @Published var isScanning = false
    @Published var error: String?
    private var analyzeTask: Task<Void, Never>?
    
    @Published private(set) var hasAnalyzed = false
        private let cacheKey = "AddMeal.lastAnalyze"
    
    @Published var mealId: String?
    
    func resetForNewAnalyze() {
            meal = Meal()
            error = nil
            hasAnalyzed = false
            UserDefaults.standard.removeObject(forKey: cacheKey)
        }
    
    func restoreFromCache() {
            guard let data = UserDefaults.standard.data(forKey: cacheKey),
                  let m = try? JSONDecoder().decode(Meal.self, from: data) else { return }
            meal = m
            hasAnalyzed = !m.title.isEmpty
        }
    
    private func persist() {
            if let data = try? JSONEncoder().encode(meal) {
                UserDefaults.standard.set(data, forKey: cacheKey)
            }
        }

    func scan(image: UIImage) {
            guard !hasAnalyzed else { return }
            isScanning = true; error = nil

            analyzeTask?.cancel()
            analyzeTask = Task { [weak self] in
                guard let self else { return }
                do {
                    let meal = try await AuthAPI.shared.analyze(image: image)
                    await MainActor.run {
                        self.meal = meal
                        self.hasAnalyzed = true
                        self.mealId = meal.id.map(String.init)            // ⬅️ сохраняем id для PATCH/RECOMPUTE
                        print("✅ ANALYZE created/updated meal id = \(self.mealId ?? "nil")")
                        self.isScanning = false
                        self.persist()
                    }
                } catch is CancellationError {
                    await MainActor.run { self.isScanning = false } // тихо отменили
                } catch {
                    await MainActor.run { self.error = error.localizedDescription; self.isScanning = false }
                }
            }
        }
    
    func saveAndRecompute(from draft: Meal) async {
        self.meal = draft
        self.persist()

        if mealId == nil, let draftId = draft.id {     // ⬅️ подхват id из черновика
            mealId = String(draftId)
        }

        guard let id = mealId else {
            print("🟡 saveAndRecompute: no mealId → локальное сохранение без PATCH/RECOMPUTE")
            return
        }

        let before = (kcal: draft.calories, p: draft.proteins, f: draft.fats, c: draft.carbs)
        let t0 = Date()
        print("📤 PATCH /api/meals/\(id)/ payload (draft):\n\(draft.prettyJSON())")

        do {
            try await AuthAPI.shared.patchMeal(id: id, from: draft)
            let t1 = Date()
            print(String(format: "✅ PATCH OK (%.2fs) → запускаем RECOMPUTE…", t1.timeIntervalSince(t0)))
            let tR0 = Date()
            print("🔄 POST /api/meals/\(id)/recompute/")

            let recomputed = try await AuthAPI.shared.recomputeMeal(id: id)
            let tR1 = Date()

            self.meal.calories     = recomputed.calories
            self.meal.proteins     = recomputed.proteins
            self.meal.fats         = recomputed.fats
            self.meal.carbs        = recomputed.carbs
            self.meal.benefitScore = recomputed.benefitScore
            self.persist()

            let delta = (
                kcal: recomputed.calories - before.kcal,
                p:    recomputed.proteins - before.p,
                f:    recomputed.fats     - before.f,
                c:    recomputed.carbs    - before.c
            )
            print(String(format:
                "⬅️ RECOMPUTE OK (%.2fs)\n→ result: kcal=%d, P=%d, F=%d, C=%d, benefit=%d\n→ Δ: kcal=%+d, P=%+d, F=%+d, C=%+d",
                tR1.timeIntervalSince(tR0),
                recomputed.calories, recomputed.proteins, recomputed.fats, recomputed.carbs, recomputed.benefitScore,
                delta.kcal, delta.p, delta.f, delta.c
            ))
        } catch {
            print("❌ saveAndRecompute failed: \(error.localizedDescription)")
            self.error = error.localizedDescription
        }
    }

    func cancelScan() { analyzeTask?.cancel() }
    
    func update(_ mutate: (inout Meal) -> Void) {
            var copy = meal
            mutate(&copy)
            meal = copy
            persist()
        }
}
