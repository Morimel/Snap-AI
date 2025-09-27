//
//  HideKeyboardOnTap.swift
//  SnapAI
//
//  Created by Isa Melsov on 26/9/25.
//

import SwiftUI
import UIKit

// MARK: - Public API
extension View {
    /// Скрывает клавиатуру при тапе по фону. Игнорирует тапы по
    /// интерактивным контролам (TextField/SecureField/UIButton/SwiftUI Button).
    func hideKeyboardOnTap() -> some View {
        modifier(DismissKeyboardOnTap())
    }
}

// MARK: - Modifier
private struct DismissKeyboardOnTap: ViewModifier {
    @State private var isKeyboardShown = false

    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
                isKeyboardShown = true
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
                isKeyboardShown = false
            }
            .overlay(
                Group {
                    if isKeyboardShown {
                        TapCatcher {
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                                            to: nil, from: nil, for: nil)
                        }
                        .ignoresSafeArea()
                    }
                }
            )
    }
}

// MARK: - Transparent overlay that forwards touches,
// with delegate to SKIP touches on interactive controls.
private struct TapCatcher: UIViewRepresentable {
    let onTap: () -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onTap: onTap) }

    func makeUIView(context: Context) -> UIView {
        let v = UIView(frame: .zero)
        v.backgroundColor = .clear

        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.tapped))
        tap.cancelsTouchesInView = false
        tap.delegate = context.coordinator    // 👈 делегат
        v.addGestureRecognizer(tap)

        return v
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        let onTap: () -> Void
        init(onTap: @escaping () -> Void) { self.onTap = onTap }

        @objc func tapped() { onTap() }

        // Не обрабатываем тапы по интерактивным контролам
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                               shouldReceive touch: UITouch) -> Bool {
            guard let view = touch.view else { return true }
            return !isInteractive(view)
        }

        private func isInteractive(_ view: UIView) -> Bool {
            var v: UIView? = view
            while let cur = v {
                // UIKit-контролы: кнопки, свичи и т.д.
                if cur is UIControl || cur is UITextField || cur is UITextView { return true }
                // SwiftUI Button часто промаркирован как .button
                if cur.accessibilityTraits.contains(.button) || cur.accessibilityTraits.contains(.link) { return true }
                v = cur.superview
            }
            return false
        }
    }
}
