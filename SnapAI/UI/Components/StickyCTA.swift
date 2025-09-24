//
//  StickyCTA.swift
//  SnapAI
//
//  Created by Isa Melsov on 23/9/25.
//

import SwiftUI

//MARK: - StickyCTA
struct StickyCTA: View {
    let title: String
    let action: () -> Void

    var body: some View {
        // фон области инсета + сама кнопка
        ZStack {
            // фон «под кнопкой», как на скрине
            Color(.white)
                .overlay(Divider().opacity(0.0), alignment: .top) // тонкая разделительная линия (optional)

            Button(action: action) {
                Text(title)
                    .font(.system(size: 20, weight: .semibold))
                    .frame(maxWidth: .infinity, minHeight: 60)
                    .foregroundColor(.white)
                    .background(AppColors.secondary)
                    .clipShape(RoundedRectangle(cornerRadius: 22))
            }
            .padding(.horizontal, 20)
        }
        .ignoresSafeArea(edges: .bottom)
        .frame(height: 88)// держим до самого края
    }
}

