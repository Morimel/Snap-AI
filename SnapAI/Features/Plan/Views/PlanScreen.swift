//
//  PlanScreen.swift
//  SnapAI
//
//  Created by Isa Melsov on 23/9/25.
//

import SwiftUI

//MARK: - PlanScreen
struct PlanScreen: View {
    
    var onNext: (() -> Void)? = nil
    
    let plan: PersonalPlan
    
    let tips: [Tip] = [
        .init(image: AppImages.Other.apple,
              title: "Eat what you love",
              subtitle: "finding delicious and\nfilling meals."),
        .init(image: AppImages.Other.calculator,
              title: "Easy food tracking",
              subtitle: "using photos for\nautomatic food\nrecognition."),
        .init(image: AppImages.Other.list1,
              title: "Follow your personalized\nplan",
              subtitle: "discovering tasty and\nsatisfying meals."),
        .init(image: AppImages.Other.weight,
              title: "Maintain balance",
              subtitle: "the right balance of\nproteins, fats, and\ncarbohydrates.")
    ]
    
    let sources = [
        "Metabolic and Nutrition Studies — National Institutes of Health (NIH).",
        "Dietary Guidelines and Calorie Recommendations — World Health Organization (WHO).",
        "Scientific Research on Nutrition — European Federation of the Associations of Dietitians (EFAD)."
    ]
    
    var body: some View {
        ScrollView {
            VStack {
                AppImages.Other.mark
                    .resizable()
                    .frame(width: 68, height: 68)
                
                Text("Your personalized plan is\nready!")
                    .padding()
                    .multilineTextAlignment(.center)
                    .foregroundStyle(AppColors.primary)
                    .font(.system(size: 24, weight: .semibold, design: .default))
                
                Text("You will maintain \(plan.maintainWeight) \(plan.weightUnit)")
                    .foregroundStyle(AppColors.primary)
                    .padding()
                    .padding(.horizontal, 4)
                    .frame(height: 40)
                    .background(
                        Capsule().fill(.white)     // белый фон
                    )
                    .overlay (
                        Capsule()
                            .stroke(AppColors.primary.opacity(0.1), lineWidth: 2)
                            .frame(width: 220, height: 40)
                    )
                
                HStack {
                    Text("Calorie and macronutrient\nrecommendations")
                        .foregroundStyle(AppColors.primary)
                        .font(.system(size: 16, weight: .semibold, design: .default))
                    
                    Spacer()
                    
                    Button {
                        print("pen")
                    } label: {
                        AppImages.ButtonIcons.Pen.darkPen
                    }
                }
                .padding(.vertical, 32)
                .padding(.horizontal, 20)
                
                HStack(spacing: 16) {
                    NutrientsCard(value: plan.dailyCalories, title: "Calories", color: AppColors.customRed)
                    NutrientsCard(value: plan.carbs, title: "Carbohydrates", color: AppColors.customOrange)
                }
                .padding(.bottom, 4)
                
                HStack(spacing: 16) {
                    NutrientsCard(value: plan.protein, title: "Proteins", color: AppColors.customBlue)
                    NutrientsCard(value: plan.fat, title: "Fats", color: AppColors.customGreen)
                }
                
                HStack {
                    Text("Helpful tips")
                        .foregroundStyle(AppColors.primary)
                        .font(.system(size: 16, weight: .semibold, design: .default))
                        .padding()
                    
                    Spacer()
                }
                .padding(.top, 32)
                .padding(.horizontal, 20)
                
                
                HelpfulTipsCard(tips: tips)
                    .padding(.horizontal, 20)
                
                
                BulletListBox(
                    title: "The plan is based on scientific research and medical recommendations",
                    items: sources
                )
                .padding()
                .background(AppColors.background.ignoresSafeArea())
            }
        }
        .background(AppColors.background.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) {
            StickyCTA(title: "Next") {
                onNext?()   // действие по кнопке
            }
        }
    }
}


#Preview {
    NavigationStack {
        PlanScreen(plan: .preview)
    }
}
