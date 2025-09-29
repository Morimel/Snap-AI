//
//  CirlceButton.swift
//  SnapAI
//
//  Created by Isa Melsov on 24/9/25.
//

import SwiftUI

struct CircleIconButton: View {
    var systemName: String = "chevron.left"
    var size: CGFloat = 40
    var iconSize: CGFloat = 18

    var bg: Color = .white
    var fg: Color = Color(red: 0.17, green: 0.36, blue: 0.29)
    var ring: Color = Color(red: 0.31, green: 0.56, blue: 0.46).opacity(0.35)
    var shadow: Color = Color(red: 0.31, green: 0.56, blue: 0.46).opacity(0.25)

    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: iconSize, weight: .semibold))
                .foregroundStyle(.black)
                .frame(width: size, height: size)
                .background(bg, in: Circle())
                .overlay(
                    Circle()
                        .stroke(ring, lineWidth: 1)
                )
                .shadow(color: shadow, radius: 6, x: 0, y: 2)
                .contentShape(Circle())
        }
        .buttonStyle(PressScaleStyle(scale: 0.96))
        .accessibilityLabel(Text("Back"))
        .padding(.trailing, 32)
    }
}

struct PressScaleStyle: ButtonStyle {
    var scale: CGFloat = 0.95
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct CircleActionButton<Inner: View>: View {
    var systemImage: String? = nil
    @ViewBuilder var inner: () -> Inner
    var action: () -> Void

    var size: CGFloat = 68

    init(systemImage: String,
         action: @escaping () -> Void) where Inner == EmptyView {
        self.systemImage = systemImage
        self.inner = { EmptyView() }
        self.action = action
    }

    init(@ViewBuilder inner: @escaping () -> Inner,
         action: @escaping () -> Void) {
        self.inner = inner
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    Circle().fill(Color.white)
                    Circle().stroke(AppColors.primary.opacity(0.15), lineWidth: 1)
                    Circle().stroke(.white.opacity(0.6), lineWidth: 1)
                        .blendMode(.plusLighter)

                    if let name = systemImage {
                        Image(systemName: name)
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(AppColors.primary)
                    } else {
                        inner()
                    }
                }
                .frame(width: size, height: size)
                .shadow(color: .black.opacity(0.20), radius: 18, y: 8)
            }
        }
        .buttonStyle(.plain)
    }
}
