//
//  CameraScreen.swift
//  SnapAI
//
//  Created by Isa Melsov on 23/9/25.
//


import SwiftUI

// MARK: - SwiftUI Camera Screen
struct CameraScreen: View {
    @Environment(\.dismiss) private var dismiss
    var onDone: (UIImage) -> Void

    @StateObject private var bridge = BridgingCoordinator()
    private struct CropItem: Identifiable, Equatable {
        let id = UUID()
        let image: UIImage
    }

    @State private var cropItem: CropItem?   // вместо showCrop + cropImage


    @State private var detectedQuad: Quad?

    var body: some View {
        ZStack {
            HostedCameraView(coordinator: bridge)
                .ignoresSafeArea()

            // верхняя панель
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(.black.opacity(0.35))
                        .clipShape(Circle())
                }
                Spacer()
                Button {
                    bridge.isTorchOn.toggle()
                    NotificationCenter.default.post(name: .toggleTorch, object: bridge.isTorchOn)
                } label: {
                    Text(bridge.isTorchOn ? "Torch On" : "Torch Off")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(.black.opacity(0.35))
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .frame(maxHeight: .infinity, alignment: .top)
            .ignoresSafeArea()

            // нижняя панель
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        NotificationCenter.default.post(name: .takePhoto, object: nil)
                    } label: {
                        ZStack {
                            Circle().fill(Color.white.opacity(0.2)).frame(width: 78, height: 78)
                            Circle().strokeBorder(Color.white, lineWidth: 3).frame(width: 74, height: 74)
                            Circle().fill(Color.white).frame(width: 60, height: 60)
                        }
                    }
                    .buttonStyle(.plain)
                    Spacer()
                }
                .padding(.bottom, 28)
            }
            .ignoresSafeArea()

            // верхняя виньетка (читаемость кнопок)
            LinearGradient(colors: [.black.opacity(0.45), .clear], startPoint: .top, endPoint: .center)
                .ignoresSafeArea()
                .allowsHitTesting(false)
        }
        .onChange(of: bridge.capturedImage) { img in
            guard let img else { return }
            cropItem = .init(image: img)   // ЭТО и есть триггер показа
        }
        .fullScreenCover(item: $cropItem) { item in
            QuadCropSheet(
                image: item.image,
                initialQuad: nil,
                onRetake: {
                    cropItem = nil
                    bridge.capturedImage = nil
                },
                onUse: { cropped in
                    cropItem = nil
                    onDone(cropped)
                }
            )
            .preferredColorScheme(.dark)
        }

    }
}
