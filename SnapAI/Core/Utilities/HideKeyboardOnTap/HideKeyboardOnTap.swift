//
//  HideKeyboardOnTap.swift
//  SnapAI
//
//  Created by Isa Melsov on 26/9/25.
//

import SwiftUI
import UIKit

// MARK: - Public API
import SwiftUI

struct DismissKeyboardOnTap: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let v = UIView()
        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handle))
        tap.cancelsTouchesInView = false   // <<< ключ!
        v.addGestureRecognizer(tap)
        return v
    }
    func updateUIView(_ uiView: UIView, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator() }
    final class Coordinator: NSObject {
        @objc func handle() {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                            to: nil, from: nil, for: nil)
        }
    }
}

extension View {
    func hideKeyboardOnTap() -> some View {
        background(DismissKeyboardOnTap())
    }
}
