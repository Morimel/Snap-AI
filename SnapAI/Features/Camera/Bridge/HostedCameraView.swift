//
//  HostedCameraView.swift
//  SnapAI
//
//  Created by Isa Melsov on 23/9/25.
//

import SwiftUI

struct HostedCameraView: UIViewControllerRepresentable {
    @ObservedObject var coordinator: BridgingCoordinator

    func makeUIViewController(context: Context) -> CameraViewController {
        CameraViewController(coordinator: coordinator)
    }

    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {
        // намеренно пусто — фонарь переключаем только через NotificationCenter
    }
}

