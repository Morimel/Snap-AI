//
//  OnboardingPhase.swift
//  SnapAI
//
//  Created by Isa Melsov on 23/9/25.
//

import SwiftUI

// MARK: - Этапы онбординга

enum OnboardingPhase: Equatable {
    case goal       
    case rate
    case submitting
    case ready
    case failed(String)
}

