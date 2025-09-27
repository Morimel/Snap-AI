//
//  MacroSummaryCard.swift
//  SnapAI
//
//  Created by Isa Melsov on 23/9/25.
//

import SwiftUI

//MARK: - MacroSummaryCard
struct MacroSummaryCard: View {
    let protein: (current: Double, target: Double)
    let fat:     (current: Double, target: Double)
    let carb:    (current: Double, target: Double)
    
    var body: some View {
        HStack(spacing: 20) {
            MacroBar(title: "Proteins",
                     current: protein.current, target: protein.target,
                     gradient: LinearGradient(gradient: Gradient(colors: [AppColors.customGreen, AppColors.primary]),
                                              startPoint: .leading, endPoint: .trailing))
            
            MacroBar(title: "Fats",
                     current: fat.current, target: fat.target,
                     gradient: LinearGradient(gradient: Gradient(colors: [AppColors.customBlue, AppColors.primary]),
                                              startPoint: .leading, endPoint: .trailing))
            
            MacroBar(title: "Carbohydrates",
                     current: carb.current, target: carb.target,
                     gradient: LinearGradient(gradient: Gradient(colors: [AppColors.customOrange, AppColors.primary]),
                                              startPoint: .leading, endPoint: .trailing))
        }
        .padding(.vertical)
    }
}


