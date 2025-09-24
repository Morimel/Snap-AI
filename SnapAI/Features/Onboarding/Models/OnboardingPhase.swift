//
//  OnboardingPhase.swift
//  SnapAI
//
//  Created by Isa Melsov on 23/9/25.
//

import SwiftUI

// MARK: - Этапы онбординга

enum OnboardingPhase: Equatable {
    case goal       // экран выбора цели
    case rate       // экран Rate
    case submitting // показываем крутилку и шлём данные
    case ready      // получили план — идём на «экран два»
    case failed(String)
}

