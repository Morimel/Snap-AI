//
//  PayWallSheet.swift
//  SnapAI
//
//  Created by Isa Melsov on 23/9/25.
//

import SwiftUI

struct PayWallSheet: View {
    @Binding var selected: Product
    var ctaTitle: String
    var onStart: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            Text("Update plan")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(AppColors.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 16)

            HStack(spacing: 12) {
                PlanCard(product: .monthly, isSelected: selected == .monthly) { selected = .monthly }
                PlanCard(product: .annual,  isSelected: selected == .annual)  { selected = .annual  }
            }
            .padding(.horizontal, 16)

            Text("*7-day free trial, then $19.99/month")
                .font(.system(size: 12))
                .foregroundStyle(AppColors.primary.opacity(0.7))
                .padding(.top, 2)

            Button(action: onStart) {
                Text(ctaTitle)
                    .font(.system(size: 20, weight: .semibold))
                    .frame(maxWidth: .infinity, minHeight: 60)
                    .foregroundColor(.white)
                    .background(AppColors.secondary)
                    .clipShape(RoundedRectangle(cornerRadius: 22))
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 12)
        }
        .shadow(color: .black.opacity(0.08), radius: 12, y: -2)
    }
}


#Preview {
    PayWallSheet(selected: .constant(.monthly), ctaTitle: "Title", onStart: { })
}
