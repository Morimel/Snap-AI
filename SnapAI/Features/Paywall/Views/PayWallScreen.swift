//
//  PayWallScreen.swift
//  SnapAI
//
//  Created by Isa Melsov on 23/9/25.
//

import SwiftUI

// MARK: - PayWallScreen
struct PayWallScreen: View {
    
    @Environment(\.dismiss) private var dismiss
    
    let features: [Features] = [
        .init(image: AppImages.Other.camera2,   title: "Food recognition by photo"),
        .init(image: AppImages.Other.toolsPlate, title: "Automatic calorie counting"),
        .init(image: AppImages.Other.list2,      title: "Personalized meal plan"),
        .init(image: AppImages.Other.statistic,  title: "Weight tracking")
    ]
    @State private var selected: Product = .annual
    
    // коэффициенты: верх 60%, низ 40%
    private let topRatio: CGFloat = 0.60
    private let bottomRatio: CGFloat = 0.40
    
    var body: some View {
        GeometryReader { geo in
            // Общая высота + safe area, затем делим 60/40
            let totalH  = geo.size.height + geo.safeAreaInsets.top + geo.safeAreaInsets.bottom
            let topH    = totalH * topRatio   - geo.safeAreaInsets.top
            let bottomH = totalH * bottomRatio + geo.safeAreaInsets.bottom
            
            ZStack {
                // сплошной фон на весь экран (чтобы под скруглениями ничего не просвечивало)
                AppColors.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // ===== Верхний блок (60%) =====
                    ZStack(alignment: .top) {
                        AppImages.Other.food2
                            .resizable()
                            .scaledToFill()
                            .frame(width: geo.size.width, height: topH + 170)
                            .clipped()
                            .overlay(
                                LinearGradient(
                                    colors: [.black.opacity(0.38), .clear],
                                    startPoint: .top, endPoint: .center
                                )
                            )
                            .offset(y: 76)
                        
                        VStack(spacing: 12) {
                            Text("Snap AI PRO")
                                .foregroundStyle(.white)
                                .font(.system(size: 40, weight: .bold))
                            
                            Text("Counting calories from\nphotos is easier than ever!")
                                .foregroundStyle(.white)
                                .font(.system(size: 16))
                                .multilineTextAlignment(.center)
                            
                            FeatureCard(features: features)
                                .padding(.top, 4)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 170)
                        .frame(maxWidth: .infinity, alignment: .top)
                    }
                    .frame(height: topH)
                    
                    // ===== Нижний блок (40%) =====
                    ZStack {
                        // фон листа со скруглениями и мягкой тенью
                        AppColors.background
                            .clipShape(RoundedCorners(corners: [.topLeft, .topRight], radius: 28))
                            .shadow(color: .black.opacity(0.08), radius: 12, y: 0)
                        
                        PayWallSheet(selected: $selected) {
                            print("Start for free with: \(selected)")
                        }
                        .padding(.bottom, 20)
                    }
                    
                    .offset(y: -10) // перекрыть шов на стыке
                    .frame(height: bottomH + 90)
                    //                    .ignoresSafeArea(edges: .bottom)
                }
            }
            .ignoresSafeArea(edges: .top)   // ← чтобы картинка залезла под навбар
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.white)
                .background(.black.opacity(0.35))
                .clipShape(Circle())
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)   // ⬅️ скрыли фон навбара
        .toolbarColorScheme(.dark, for: .navigationBar)    // светлые элементы
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
    }
}
