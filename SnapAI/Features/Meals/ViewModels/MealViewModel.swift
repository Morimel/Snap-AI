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

    func scan(image: UIImage) async {
        isScanning = true; error = nil
        do {
            let m = try await AuthAPI.shared.analyze(image: image)
            self.meal = m
        } catch {
            self.error = error.localizedDescription
        }
        isScanning = false
    }
}
