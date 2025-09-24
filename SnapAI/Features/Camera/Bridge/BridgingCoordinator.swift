//
//  BridgingCoordinator.swift
//  SnapAI
//
//  Created by Isa Melsov on 23/9/25.
//

import SwiftUI

// MARK: - Bridge
final class BridgingCoordinator: ObservableObject {
    @Published var capturedImage: UIImage?
    @Published var isTorchOn = false     // для отображения статуса в UI
}

