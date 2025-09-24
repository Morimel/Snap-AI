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

    // положи ключ в Keychain и передай сюда
    func scan(image: UIImage, apiKey: String) async {
        isScanning = true; error = nil
        do {
            let result = try await FoodScanService.scan(image: image, apiKey: apiKey)
            self.meal = result
        } catch {
            self.error = error.localizedDescription
        }
        isScanning = false
    }
}

