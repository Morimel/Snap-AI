//
//  CapsuleNavigationButton.swift
//  SnapAI
//
//  Created by Isa Melsov on 24/9/25.
//

import SwiftUI

struct CapsuleNavigationButton: ButtonStyle {
    var background: Color
    var foreground: Color
    var radius: CGFloat = 18

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity, minHeight: 56)
            .foregroundStyle(foreground)
            .background(RoundedRectangle(cornerRadius: radius).fill(background))
            .overlay(RoundedRectangle(cornerRadius: radius).stroke(foreground.opacity(0.10), lineWidth: 1))
            .overlay(
                RoundedRectangle(cornerRadius: radius)
                    .stroke(Color.white.opacity(0.9), lineWidth: 1)
                    .blendMode(.overlay)
                    .offset(y: -1)
                    .mask(
                        RoundedRectangle(cornerRadius: radius)
                            .fill(LinearGradient(colors: [.white, .clear],
                                                 startPoint: .top, endPoint: .bottom))
                    )
            )
            .shadow(color: foreground.opacity(0.18), radius: 8, x: 0, y: configuration.isPressed ? 2 : 6)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.9), value: configuration.isPressed)
    }
}


