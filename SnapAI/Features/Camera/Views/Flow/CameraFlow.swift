//
//  CameraFlow.swift
//  SnapAI
//
//  Created by Isa Melsov on 23/9/25.
//

import SwiftUI

//MARK: - CameraFlow
struct CameraFlow: View {
    enum Step {
        case camera
        case detail(UIImage)
    }

    @State private var step: Step = .camera
    @StateObject private var vm = MealViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Group {
            switch step {
            case .camera:
                CameraScreen { cropped in
                    let normalized = cropped.normalizedUp(maxDimension: 2048)
                    step = .detail(normalized)
                }
                .statusBarHidden(true)

            case .detail(let img):
                MealDetailScreen(image: img, vm: vm)
                    .toolbar {            // кнопка закрытия шита
                        ToolbarItem(placement: .topBarLeading) {
                            Button {
                                dismiss()
                            } label: {
                                Image(systemName: "xmark")
                            }
                        }
                    }
            }
        }
    }
}
