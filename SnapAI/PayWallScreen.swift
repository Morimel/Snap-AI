//
//  PayWallScreen.swift
//  SnapAI
//
//  Created by Isa Melsov on 19/9/25.
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





struct PayWallSheet: View {
    @Binding var selected: Product
    var onStart: () -> Void
    var body: some View {
        VStack(spacing: 14) {
            // Заголовок
            Text("Update plan")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(AppColors.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 16)
            
            // Карточки тарифов
            HStack(spacing: 12) {
                PlanCard(product: .monthly, isSelected: selected == .monthly) {
                    selected = .monthly
                }
                PlanCard(product: .annual,  isSelected: selected == .annual) {
                    selected = .annual
                }
            }
            .padding(.horizontal, 16)
            
            // подпись
            Text("*7-day free trial, then $19.99/month")
                .font(.system(size: 12))
                .foregroundStyle(AppColors.primary.opacity(0.7))
                .padding(.top, 2)
            
            // CTA
            Button(action: onStart) {
                Text("Start for free")
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

// MARK: - Helpers
private struct RoundedCorners: Shape {
    var corners: UIRectCorner = .allCorners
    var radius: CGFloat = 16
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}


enum Product: String, CaseIterable, Identifiable {
    case monthly, annual
    var id: Self { self }
    
    var title: String {
        switch self {
        case .monthly: return "Monthly plan"
        case .annual:  return "Annual plan"
        }
    }
    var price: String {
        switch self {
        case .monthly: return "$19.99"
        case .annual:  return "$59.99"
        }
    }
    var period: String {
        switch self {
        case .monthly: return "per month"
        case .annual:  return "per year"
        }
    }
    var badge: (text: String, foreground: Color, background: Color)? {
        switch self {
        case .monthly:
            return ("Popular", .white, AppColors.secondary)
        case .annual:
            return ("Save 75%", AppColors.primary, AppColors.primary.opacity(0.12))
        }
    }
}



// MARK: - PlanCard
private struct PlanCard: View {
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

struct FeatureCard: View {
    let features: [Features]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(features.indices, id: \.self) { i in
                FeatureRow(feature: features[i])
            }
        }
    }
}

struct FeatureRow: View {
    let feature: Features
    var body: some View {
        HStack( spacing: 12) {
            feature.image
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
                .accessibilityHidden(true)
            
            
            Text(feature.title)
                .font(.system(size: 16))
                .foregroundStyle(.white)
        }
    }
}


struct Features {
    let image: Image
    let title: String
}

// MARK: - Preview
#Preview {
        NavigationStack { PayWallScreen() }
    }
