//
//  CameraNotifications.swift
//  SnapAI
//
//  Created by Isa Melsov on 23/9/25.
//

import Foundation

// MARK: - Notifications
extension Notification.Name {
    static let takePhoto    = Notification.Name("snapai.takePhoto")
    static let toggleTorch  = Notification.Name("snapai.toggleTorch")
    static let pauseCamera  = Notification.Name("snapai.camera.pause")   
    static let resumeCamera = Notification.Name("snapai.camera.resume")
}
