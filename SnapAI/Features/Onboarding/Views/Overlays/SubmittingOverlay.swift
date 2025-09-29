//
//  SubmittingOverlay.swift
//  SnapAI
//
//  Created by Isa Melsov on 23/9/25.
//

import SwiftUI

//MARK: -  SubmittingOverlay
struct SubmittingOverlay: View {
    let title: String
    let subtitle: String?
    @Binding var progress: Double
    var onCancel: (() -> Void)?
    
    var body: some View {
        ZStack {
            AppColors.background.opacity(0.98).ignoresSafeArea()
            
            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .stroke(lineWidth: 24)
                        .frame(width: 300, height: 300)
                        .foregroundStyle(
                            LinearGradient(gradient: Gradient(colors: [AppColors.background, AppColors.primary]),
                                           startPoint: .top, endPoint: .bottomLeading)
                        )
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 10, y: 10)
                    
                    Circle()
                        .trim(from: 0, to: progress) // 👈 ПРОГРЕСС
                        .stroke(style: StrokeStyle(lineWidth: 24, lineCap: .round))
                        .frame(width: 300, height: 300)
                        .rotationEffect(.degrees(-90))
                        .foregroundStyle(
                            LinearGradient(gradient: Gradient(colors: [AppColors.secondary, AppColors.primary]),
                                           startPoint: .top, endPoint: .bottomLeading)
                        )
                        .animation(.easeInOut(duration: 0.25), value: progress)
                    
                    Circle()
                        .frame(width: 220, height: 220)
                        .foregroundStyle(
                            LinearGradient(gradient: Gradient(colors: [AppColors.primary, AppColors.secondary]),
                                           startPoint: .top, endPoint: .bottom)
                        )
                    
                    Circle()
                        .stroke(style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 225, height: 225)
                        .foregroundStyle(
                            LinearGradient(gradient: Gradient(colors: [AppColors.background, AppColors.primary]),
                                           startPoint: .top, endPoint: .bottomLeading)
                        )
                        .shadow(color: .black.opacity(0.4), radius: 10, x: 10, y: 10)
                    
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 32, weight: .semibold, design: .default))
                        .foregroundColor(.white)
                        .padding()
                }
                
                Text(title)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(AppColors.primary)
                
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(AppColors.primary.opacity(0.7))
                }
                
                if let onCancel {
                    Button("Отмена", action: onCancel)
                        .padding(.top, 4)
                }
            }
            .padding()
        }
    }
}
