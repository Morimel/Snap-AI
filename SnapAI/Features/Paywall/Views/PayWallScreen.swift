//
//  PayWallScreen.swift
//  SnapAI
//
//  Created by Isa Melsov on 23/9/25.
//

import SwiftUI

// MARK: - PayWallScreen
struct PayWallScreen: View {
    
    var mode: PaywallMode
    var onStartTrial: () -> Void     // используется и для ✕, и для "Start for free"
    var onProceed: () -> Void        // "Pay"
    
    // ↑ добавим настройки
    private let imageYOffset: CGFloat = 124   // минус = выше картинка
    private let sheetYOffset: CGFloat = -12    // плюс = ниже нижний блок
    private let extraImageHeight: CGFloat = 200 // запас высоты, чтобы картинка не
    private let topRatio: CGFloat = 0.65
    private let bottomRatio: CGFloat = 0.35
    
    let features: [Features] = [
        .init(image: AppImages.Other.camera2,   title: "Food recognition by photo"),
        .init(image: AppImages.Other.toolsPlate, title: "Automatic calorie counting"),
        .init(image: AppImages.Other.list2,      title: "Personalized meal plan"),
        .init(image: AppImages.Other.statistic,  title: "Weight tracking")
    ]
    @State private var selected: Product = .annual
    
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
                    ZStack(alignment: .center) {
                        AppImages.OtherImages.food2
                            .resizable()
                            .scaledToFill()
                            .frame(width: geo.size.width, height: topH + 248)
                            .clipped()
                            .overlay(
                                LinearGradient(
                                    colors: [.black.opacity(0.38), .clear],
                                    startPoint: .top, endPoint: .center
                                )
                            )
                            .offset(y: imageYOffset)
                        
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
                        .frame(maxWidth: .infinity, alignment: .top)
                    }
                    .frame(height: topH)
                    
                    // ===== Нижний блок (40%) =====
                    ZStack {
                        // фон листа со скруглениями и мягкой тенью
                        AppColors.background
                            .clipShape(RoundedCorners(corners: [.topLeft, .topRight], radius: 28))
                            .shadow(color: .black.opacity(0.08), radius: 12, y: 0)
                        
                        PayWallSheet(
                            selected: $selected,
                            ctaTitle: mode.ctaTitle,
                            onStart: {
                                if mode == .trialOffer {
                                    onStartTrial()
                                } else {
                                    onProceed()
                                }
                            },
                            mode: mode
                        )
                    }
                    .offset(y: sheetYOffset)        // ← ОПУСТИЛИ «зелёную» часть
                    .frame(height: bottomH)
                }
            }
            // КРЕСТИК — собственный оверлей, а не toolbar
            .overlay(alignment: .topTrailing) {
                if mode.showsClose {
                    Button(action: onStartTrial) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(10)
                            .background(.black.opacity(0.35))
                            .clipShape(Circle())
                    }
                    .padding(.top, geo.safeAreaInsets.top + 48)
                    .padding(.trailing, 24)
                }
            }
        }
        .ignoresSafeArea()
    }
}

#Preview {
    PaywallPreview()
}

private struct PaywallPreview: View {
    @State private var path = NavigationPath()
    var body: some View {
        NavigationStack(path: $path) {
            PayWallScreen(
                mode: .trialOffer,
                onStartTrial: {},
                onProceed: {}
            )
        }
    }
}
