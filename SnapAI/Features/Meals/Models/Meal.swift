//
//  Meal.swift
//  SnapAI
//
//  Created by Isa Melsov on 23/9/25.
//

import SwiftUI

struct Meal: Codable, Hashable  {
    var id: Int? = nil
    var title: String = ""
    var calories: Int = 0
    var proteins: Int = 0
    var fats: Int = 0
    var carbs: Int = 0
    var servings: Int = 1
    var benefitScore: Int = 0   
    var ingredients: [Ingredient] = []
    
    var imagePath: String? = nil
}

struct Ingredient: Identifiable, Codable, Hashable {
    var id: UUID = .init()
    var name: String
    var kcal: Int
}

extension Meal {
    static let mock = Meal(
        title: "Teriyaki chicken with rice",
        calories: 241, proteins: 50, fats: 32, carbs: 150, servings: 1, benefitScore: 5,
        ingredients: [
            .init(name: "Chicken breast", kcal: 330),
            .init(name: "Teriyaki sauce", kcal: 210),
            .init(name: "Vegetable oil", kcal: 270),
            .init(name: "Rice", kcal: 340)
        ]
    )
}

extension Notification.Name {
    static let dismissToMainFromEdit = Notification.Name("dismissToMainFromEdit")
}
