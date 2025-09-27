//
//  StatisticsCard.swift
//  SnapAI
//
//  Created by Isa Melsov on 23/9/25.
//

import SwiftUI

//MARK: - StatisticsCard
struct StatisticsCard: View {
    var body: some View {
        
        let kcal = 1758
        
        let kcalNeeded = 2569
        
        let kcalSpent = 811
        
        VStack {
            ZStack {
                Circle()
                    .stroke(lineWidth: 10)
                    .frame(width: 110, height: 110)
                    .foregroundStyle(LinearGradient(gradient: Gradient(colors: [.white, .black.opacity(0.6)]), startPoint: .top, endPoint: .bottomLeading))
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 10, y: 10)
                
                Circle()
                    .trim(from: 0, to: 0.5)
                    .stroke(lineWidth: 10)
                    .frame(width: 110, height: 110)
                    .rotationEffect(.degrees(-90))
                    .foregroundStyle(LinearGradient(gradient: Gradient(colors: [AppColors.customBlue]), startPoint: .top, endPoint: .bottomLeading))
                
                Circle()
                    .stroke(lineWidth: 8)
                    .frame(width: 156, height: 156)
                    .foregroundStyle(LinearGradient(gradient: Gradient(colors: [.white, .black.opacity(0.6)]), startPoint: .top, endPoint: .bottomLeading))
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 10, y: 10)
                
                Circle()
                    .trim(from: 0, to: 0.5)
                    .stroke(lineWidth: 8)
                    .frame(width: 156, height: 156)
                    .rotationEffect(.degrees(-90))
                    .foregroundStyle(LinearGradient(gradient: Gradient(colors: [AppColors.customOrange]), startPoint: .top, endPoint: .bottomLeading))
                
                
                Circle()
                    .stroke(lineWidth: 12)
                    .frame(width: 200, height: 200)
                    .foregroundStyle(LinearGradient(gradient: Gradient(colors: [.white, .black.opacity(0.6)]), startPoint: .top, endPoint: .bottomLeading))
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 10, y: 10)
                
                Circle()
                    .trim(from: 0, to: 0.6)
                    .stroke(lineWidth: 12)
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))
                    .foregroundStyle(LinearGradient(gradient: Gradient(colors: [AppColors.customGreen]), startPoint: .top, endPoint: .bottomLeading))
                
                VStack {
                    Text("\(kcal)")
                        .foregroundStyle(AppColors.primary)
                        .font(.system(size: 24, weight: .bold, design: .default))
                    
                    Text("kcal")
                        .foregroundStyle(AppColors.primary)
                        .font(.system(size: 12, weight: .regular, design: .default))
                }
            }
            .padding(.top, 20)
            HStack {
                VStack {
                    Text("\(kcalNeeded)")
                        .foregroundStyle(AppColors.primary)
                        .font(.system(size: 20, weight: .bold, design: .default))
                    
                    Text("Need it today")
                        .foregroundStyle(AppColors.secondary)
                        .font(.system(size: 12, weight: .regular, design: .default))
                }
                .padding(.horizontal, 36)
                
                
                VStack {
                    Text("\(kcalSpent)")
                        .foregroundStyle(AppColors.primary)
                        .font(.system(size: 20, weight: .bold, design: .default))
                    
                    Text("Already spent")
                        .foregroundStyle(AppColors.secondary)
                        .font(.system(size: 12, weight: .regular, design: .default))
                }
                .padding(.horizontal, 36)
            }
            
            MacroSummaryCard(
                protein: (150, 220),
                fat:     (56,  88),
                carb:    (150, 220)
            )
            .padding(.horizontal)
        }
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(Color.black.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.06), radius: 10, y: 4)
        .padding()
    }
}
