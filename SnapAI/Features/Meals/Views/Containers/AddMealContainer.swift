//
//  AddMealContainer.swift
//  SnapAI
//
//  Created by Isa Melsov on 23/9/25.
//

import SwiftUI


//MARK: - AddMealContainer
struct AddMealContainer: View {
    @StateObject private var coordinator = BridgingCoordinator()
    @StateObject private var vm = MealViewModel()

    var body: some View {
        Group {
            if let image = coordinator.capturedImage {
                MealDetailScreen(image: image, vm: vm)   // 👉 экран из дизайна
            } else {
                HostedCameraView(coordinator: coordinator)
                    .ignoresSafeArea()
            }
        }
    }
}
