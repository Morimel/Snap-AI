//
//  NutrientsCard.swift
//  SnapAI
//
//  Created by Isa Melsov on 23/9/25.
//

import SwiftUI

//MARK: - NutrientsCard
struct NutrientsCard: View {
    let value: Int
    let title: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .center) {
            Text("\(title)")
                .padding(.vertical, 16)
                .foregroundStyle(AppColors.primary)
                .font(.system(size: 18, weight: .regular, design: .default))
            
            ZStack {
                Circle()
                    .stroke(lineWidth: 12)
                    .frame(width: 128, height: 128)
                    .foregroundStyle(color.opacity(0.5))
                
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .frame(width: 128, height: 128)
                    .rotationEffect(.degrees(-90))
                    .foregroundStyle(LinearGradient(gradient: Gradient(colors: [color, color.opacity(0.3)]), startPoint: .topLeading, endPoint: .bottom))
                
                Text("\(value)")
                    .foregroundStyle(AppColors.primary)
                    .font(.system(size: 24, weight: .bold, design: .default))
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 4)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(AppColors.primary.opacity(0.2), lineWidth: 2)
            )
        
        
    }
}

#Preview {
    NutrientsCard(value: 1, title: "title", color: .red)
}
