//
//  OnBoardingData.swift
//  SnapAI
//
//  Created by Isa Melsov on 16/9/25.
//

import SwiftUI

enum Gender: String, Codable { case male, female, other }
enum UnitSystem: String, Codable, CaseIterable { case imperial, metric }
enum Lifestyle: String, Codable { case sedentary, normal, active }
enum Goal: String, Codable { case lose, gain, maintain }

struct OnboardingData: Codable {
    var gender: Gender?
    var unit: UnitSystem = .metric
    var weight: Double?
    var height: Double?
    var birthDate: Date?
    var lifestyle: Lifestyle?
    var goal: Goal?
    var desiredWeight: Double?
    var rating: Int?             // из экрана Rate
}

