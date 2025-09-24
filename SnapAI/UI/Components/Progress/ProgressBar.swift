//
//  ProgressBar.swift
//  SnapAI
//
//  Created by Isa Melsov on 18/9/25.
//

import SwiftUI

struct ProgressBar: View {
    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: 24)
                .frame(width: 300, height: 300)
                .foregroundStyle(LinearGradient(gradient: Gradient(colors: [AppColors.background, AppColors.primary]), startPoint: .top, endPoint: .bottomLeading))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 10, y: 10)
            Circle()
                .trim(from: 0, to: 0.7)
                .stroke(style: StrokeStyle(lineWidth: 24, lineCap: .round))
                .frame(width: 300, height: 300)
                .rotationEffect(.degrees(-90))
                .foregroundStyle(LinearGradient(gradient: Gradient(colors: [AppColors.secondary, AppColors.primary]), startPoint: .top, endPoint: .bottomLeading))
            
            Circle()
                .frame(width: 220, height: 220)
                .foregroundStyle(LinearGradient(gradient: Gradient(colors: [AppColors.primary, AppColors.secondary]), startPoint: .top, endPoint: .bottom))
            
            Circle()
                .stroke(style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .frame(width: 225, height: 225)
                .foregroundStyle(LinearGradient(gradient: Gradient(colors: [AppColors.background, AppColors.primary]), startPoint: .top, endPoint: .bottomLeading))
                .shadow(color: .black.opacity(0.4), radius: 10, x: 10, y: 10)
            
            Text("\(Int(0.7 * 100))%")
                .font(.system(size: 32, weight: .semibold, design: .default))
                .foregroundColor(.white)
                .padding()


        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background)
    }
}

#Preview {
    ProgressBar()
}
