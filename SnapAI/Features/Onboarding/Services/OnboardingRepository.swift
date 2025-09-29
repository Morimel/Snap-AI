//
//  OnboardingRepository.swift
//  SnapAI
//
//  Created by Isa Melsov on 23/9/25.
//

import SwiftUI

// MARK: - Репозиторий
protocol OnboardingRepository {
    func submitOnboarding(data: OnboardingData) async throws
    func requestAiPersonalPlan(from data: OnboardingData) async throws
    func fetchSavedPlan() -> PersonalPlan?
}

extension OnboardingRepository {
    func fetchSavedPlan() -> PersonalPlan? { nil }
}
