//
//  AddMealContainer.swift
//  SnapAI
//
//  Created by Isa Melsov on 23/9/25.
//

import SwiftUI
import Combine
import UIKit

struct AddMealContainer: View {
    @StateObject private var coordinator = BridgingCoordinator()
    @StateObject private var vm = MealViewModel()
    @Environment(\.dismiss) private var dismiss   // 👈

    private struct CropSession: Identifiable { let id = UUID(); let image: UIImage }
    @State private var cropSession: CropSession?
    @State private var croppedImage: UIImage?

    var body: some View {
        Group {
            if let img = croppedImage {
                MealDetailScreen(image: img, vm: vm, onClose: {
                    // вернуться в камеру
                    dismiss()
                })
            } else {
                HostedCameraView(coordinator: coordinator)
                    .onReceive(coordinator.$capturedImage.compactMap { $0 }) { raw in
                        cropSession = .init(image: raw)
                        coordinator.capturedImage = nil
                    }
                    .sheet(item: $cropSession) { s in
                        QuadCropSheet(
                            image: s.image,
                            initialQuad: nil,
                            onRetake: { cropSession = nil },
                            onUse: { cropped in
                                croppedImage = cropped
                                cropSession = nil
                            }
                        )
                    }
            }
        }
        .sheet(item: $cropSession) { s in
            QuadCropSheet(
                image: s.image,
                initialQuad: nil,
                onRetake: {
                    cropSession = nil
                    NotificationCenter.default.post(name: .resumeCamera, object: nil) // ← вернули камеру
                },
                onUse: { cropped in
                    croppedImage = cropped
                    cropSession = nil
                    // камера не нужна — оставляем выключенной
                }
            )
        }

    }
}

