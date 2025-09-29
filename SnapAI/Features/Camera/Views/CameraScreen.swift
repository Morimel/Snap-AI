//
//  CameraScreen.swift
//  SnapAI
//
//  Created by Isa Melsov on 23/9/25.
//


import SwiftUI
import PhotosUI

// MARK: - SwiftUI Camera Screen

struct CameraScreen: View {
    @Environment(\.dismiss) private var dismiss
    var onDone: (UIImage) -> Void

    @StateObject private var bridge = BridgingCoordinator()

    private struct CropItem: Identifiable, Equatable {
        let id = UUID()
        let image: UIImage
    }

    @State private var pickerItem: PhotosPickerItem?
    @State private var showPicker = false
    @State private var cropItem: CropItem?

    var body: some View {
        content
            /// КАМЕРА  кроп
            .onChange(of: bridge.capturedImage) { img in
                guard let img else { return }
                cropItem = .init(image: img)
            }
            /// ГАЛЕРЕЯ  кроп
            .onChange(of: pickerItem) { item in
                guard let item else { return }
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        cropItem = .init(image: uiImage)
                    }
                    pickerItem = nil
                }
            }
            /// Пауза/резюм камеры, пока открыт кроп
            .onChange(of: cropItem) { item in
                NotificationCenter.default.post(
                    name: item == nil ? .resumeCamera : .pauseCamera, object: nil
                )
            }
            /// Пауза/резюм на время пикера
            .onChange(of: showPicker) { isShown in
                NotificationCenter.default.post(
                    name: isShown ? .pauseCamera : .resumeCamera, object: nil
                )
            }
            /// Лист кропа
            .fullScreenCover(item: $cropItem, content: cropSheet)
    }

    // MARK: - Composition

    @ViewBuilder private var content: some View {
        ZStack {
            cameraLayer
            bottomBar
            vignette
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(.black.opacity(0.35))
                        .clipShape(Circle())
                }
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    bridge.isTorchOn.toggle()
                    NotificationCenter.default.post(name: .toggleTorch, object: bridge.isTorchOn)
                } label: {
                    Text(bridge.isTorchOn ? "Torch On" : "Torch Off")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(bridge.isTorchOn ? AppColors.secondary : .black.opacity(0.6))
                        .clipShape(Capsule())
                }
            }
        }
    }

    private var cameraLayer: some View {
        HostedCameraView(coordinator: bridge)
            .ignoresSafeArea()
    }

    private var bottomBar: some View {
        VStack {
            Spacer()
            HStack(spacing: 12) {
                Button {
                    showPicker = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "photo.on.rectangle").imageScale(.large)
                        Text("Gallery").font(.subheadline)
                        Spacer()
                    }
                    .foregroundStyle(AppColors.primary)
                    .padding(.horizontal, 14)
                    .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
                    .contentShape(RoundedRectangle(cornerRadius: 22))
                }
                .buttonStyle(.plain)
                .photosPicker(
                    isPresented: $showPicker,
                    selection: $pickerItem,
                    matching: .images,
                    photoLibrary: .shared()
                )


                /// Кнопка камеры
                Button {
                    NotificationCenter.default.post(name: .takePhoto, object: nil)
                } label: {
                    ZStack {
                        Circle().fill(AppColors.primary.opacity(0.18))
                        Circle().stroke(AppColors.primary.opacity(0.25), lineWidth: 2)
                        Image(systemName: "camera.fill")
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(AppColors.primary)
                    }
                    .frame(width: 64, height: 64)
                }
                .buttonStyle(.plain)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(AppColors.background)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(AppColors.primary.opacity(0.08), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.15), radius: 20, y: 8)
            .padding(.horizontal, 16)
            .padding(.bottom, 18)
        }
        .ignoresSafeArea()
    }

    private var vignette: some View {
        LinearGradient(colors: [.black.opacity(0.45), .clear], startPoint: .top, endPoint: .center)
            .ignoresSafeArea()
            .allowsHitTesting(false)
    }

    // MARK: - Crop sheet

    @ViewBuilder
    private func cropSheet(_ item: CropItem) -> some View {
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


#Preview {
    NavigationStack {
        CameraScreen { _ in }
    }
}
