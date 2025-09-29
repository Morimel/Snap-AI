//
//  StatisticsCard.swift
//  SnapAI
//
//  Created by Isa Melsov on 23/9/25.
//

import SwiftUI

//MARK: - StatisticsCard
struct StatisticsCard: View {
    
    let needKcal: Int
    let spentKcal: Int
    
        let protein: (current: Int, max: Int)
        let fat:     (current: Int, max: Int)
        let carb:    (current: Int, max: Int)
    
    private var remaining: Int { max(needKcal - spentKcal, 0) }

    private func pct(current: Int, target: Int) -> CGFloat {
        guard target > 0 else { return 0 }
        let clamped = min(Swift.max(0, current), target)
        return CGFloat(clamped) / CGFloat(target)
    }
    
    var body: some View {
                
        let pPct = pct(current: protein.current, target: protein.max)
        let cPct = pct(current: carb.current,    target: carb.max)
        let fPct = pct(current: fat.current,     target: fat.max)
        
        VStack {
            ZStack {
                Circle()
                    .stroke(lineWidth: 10)
                    .frame(width: 110, height: 110)
                    .foregroundStyle(LinearGradient(gradient: Gradient(colors: [.white, .black.opacity(0.6)]), startPoint: .top, endPoint: .bottomLeading))
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 10, y: 10)
                
                Circle()
                    .trim(from: 0, to: pPct)
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
                    .trim(from: 0, to: cPct)
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
                    .trim(from: 0, to: fPct)
                    .stroke(lineWidth: 12)
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))
                    .foregroundStyle(LinearGradient(gradient: Gradient(colors: [AppColors.customGreen]), startPoint: .top, endPoint: .bottomLeading))
                
                VStack {
                    Text("\(remaining)")
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
                    Text("\(needKcal)")
                        .foregroundStyle(AppColors.primary)
                        .font(.system(size: 20, weight: .bold, design: .default))
                    
                    Text("Need it today")
                        .foregroundStyle(AppColors.secondary)
                        .font(.system(size: 12, weight: .regular, design: .default))
                }
                .padding(.horizontal, 36)
                
                
                VStack {
                    Text("\(spentKcal)")
                        .foregroundStyle(AppColors.primary)
                        .font(.system(size: 20, weight: .bold, design: .default))
                    
                    Text("Already spent")
                        .foregroundStyle(AppColors.secondary)
                        .font(.system(size: 12, weight: .regular, design: .default))
                }
                .padding(.horizontal, 36)
            }
            
            MacroSummaryCard(
                protein: (Double(protein.current), Double(protein.max)),
                fat:     (Double(fat.current),     Double(fat.max)),
                carb:    (Double(carb.current),    Double(carb.max))
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
        .animation(.easeInOut(duration: 0.25), value: needKcal)
                .animation(.easeInOut(duration: 0.25), value: spentKcal)
                .animation(.easeInOut(duration: 0.25), value: protein.current)
                .animation(.easeInOut(duration: 0.25), value: carb.current)
                .animation(.easeInOut(duration: 0.25), value: fat.current)
    }
}
