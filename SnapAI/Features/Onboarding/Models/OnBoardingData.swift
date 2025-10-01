//
//  OnBoardingData.swift
//  SnapAI
//
//  Created by Isa Melsov on 16/9/25.
//

import SwiftUI

extension Gender {
    var displayName: String {
        switch self {
        case .male:   return "Male"
        case .female: return "Female"
        case .other:  return "Other"
        }
    }
    static func fromDisplay(_ s: String) -> Gender {
        switch s.lowercased() {
        case "male": return .male
        case "female": return .female
        default: return .other
        }
    }
}


enum Gender: String, Codable { case male, female, other }
enum UnitSystem: String, Codable, CaseIterable { case imperial, metric }
enum Lifestyle: String, Codable { case sedentary, normal, active }
enum Goal: String, Codable { case lose, gain, maintain }

struct OnboardingData: Codable {
    var email: String? 
    var gender: Gender?
    var unit: UnitSystem = .imperial
    var weight: Double?
    var height: Double?
    var birthDate: Date?
    var lifestyle: Lifestyle?
    var goal: Goal?
    var desiredWeight: Double?
    var rating: Int?
}



