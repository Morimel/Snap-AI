//
//  PlanCard.swift
//  SnapAI
//
//  Created by Isa Melsov on 23/9/25.
//

import SwiftUI

// MARK: - PlanCard
struct PlanCard: View {
    let product: Product
    let isSelected: Bool
    let tap: () -> Void
    
    var body: some View {
        Button(action: tap) {
            VStack(alignment: .leading, spacing: 6) {
                Text(product.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppColors.primary)
                
                Text(product.price)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(AppColors.primary)
                
                Text(product.period)
                    .font(.system(size: 13))
                    .foregroundStyle(AppColors.primary.opacity(0.7))
                
                if let badge = product.badge {
                    Text(badge.text)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(badge.foreground)
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(badge.background)
                        .clipShape(Capsule())
                        .padding(.top, 6)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? AppColors.secondary : AppColors.primary.opacity(0.12), lineWidth: isSelected ? 2 : 1)
            )
            .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
    }
}
