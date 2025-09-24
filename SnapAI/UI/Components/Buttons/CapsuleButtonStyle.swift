//
//  CapsuleButtonStyle.swift
//  SnapAI
//
//  Created by Isa Melsov on 23/9/25.
//

import SwiftUI

struct CapsuleButtonStyle: ButtonStyle {
    enum Role { case primary, secondary, outline, destructive
        case custom(bg: Color, fg: Color = .white, border: Color = .clear, borderWidth: CGFloat = 0)
    }
    enum Size { case large, medium, small }

    var role: Role = .primary
    var size: Size = .large

    // ✅ Явный инициализатор для роли
    init(role: Role = .primary, size: Size = .large) {
        self.role = role
        self.size = size
    }

    // Твой кастомный инициализатор по бэкграунду
    init(background: Color, size: Size = .large, foreground: Color = .white) {
        self.role = .custom(bg: background, fg: foreground)
        self.size = size
    }

    func makeBody(configuration: Configuration) -> some View { /* как было */ }
}

// Сахар
extension ButtonStyle where Self == CapsuleButtonStyle {
    static func capsule(_ role: CapsuleButtonStyle.Role = .primary,
                        size: CapsuleButtonStyle.Size = .large) -> CapsuleButtonStyle {
        CapsuleButtonStyle(role: role, size: size)   // ✅ теперь существует
    }
}
