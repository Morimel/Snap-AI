//
//  OnboardingData+UI.swift
//  SnapAI
//
//  Created by Isa Melsov on 23/9/25.
//

import SwiftUI

extension OnboardingData {
    var genderImage: Image {
        switch gender {
        case .male:   return AppImages.Goal.maleGoal
        case .female: return AppImages.Goal.femaleGoal
        case .other, .none: return Image(systemName: "gear")
        }
    }
    var weightUnitLabel: String { unit == .imperial ? "lbs" : "kg" }
}

