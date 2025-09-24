//
//  Untitled.swift
//  SnapAI
//
//  Created by Isa Melsov on 23/9/25.
//

import SwiftUI

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
