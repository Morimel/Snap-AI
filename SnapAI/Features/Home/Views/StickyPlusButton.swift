//
//  StickyPlusButton.swift
//  SnapAI
//
//  Created by Isa Melsov on 23/9/25.
//

import SwiftUI

//MARK: - StickyPlusButton
struct StickyPlusButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {                    // 👈 вызываем action()
            AppImages.ButtonIcons.Plus.lightPlus
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
                .padding(.vertical, 18)             // побольше кликабельная зона
        }
        .frame(width: 80, height: 56)
        .background(Capsule().fill(AppColors.secondary))
        .foregroundStyle(.white)
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .shadow(color: .black.opacity(0.15), radius: 8, y: 2)
    }
}


