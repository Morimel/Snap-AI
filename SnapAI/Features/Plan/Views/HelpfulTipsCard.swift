//
//  HelpfulTipsCard.swift
//  SnapAI
//
//  Created by Isa Melsov on 23/9/25.
//

import SwiftUI

//MARK: - HelpfulTipsCard
struct HelpfulTipsCard: View {
    let tips: [Tip]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(tips.indices, id: \.self) { i in
                TipRow(tip: tips[i])
                    .padding()
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(.white))
        .overlay(RoundedRectangle(cornerRadius: 16)
            .stroke(AppColors.primary.opacity(0.12), lineWidth: 1))
        .shadow(color: .black.opacity(0.06), radius: 10, y: 4)
    }
}
