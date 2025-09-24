//
//  PersonalPlan+Preview.swift
//  SnapAI
//
//  Created by Isa Melsov on 23/9/25.
//

import SwiftUI

//MARK: - PersonalPlan
extension PersonalPlan {
    static let preview: PersonalPlan = .init(
        weightUnit: "lbs",
        maintainWeight: 121,
        dailyCalories: 2000,
        protein: 140,
        fat: 70,
        carbs: 180,
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
}
