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
    
    @State private var path = NavigationPath()
    @State private var showChangeTarget = false
    let goalCaption: String   // 👈 добавили
    
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @Environment(\.dismiss) private var dismiss
    
    @EnvironmentObject private var paywall: PaywallCenter
    @State private var showPaywallScreen = false
    
    @EnvironmentObject var vm: OnboardingViewModel

    private var current: PersonalPlan { vm.personalPlan ?? plan }
    
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
                    
                    Text(goalCaption)
                                            .foregroundStyle(AppColors.primary)
                                            .padding()
                                            .frame(height: 40)
                                            .background(Capsule().fill(.white))
//                                            .overlay(
//                                                Capsule()
//                                                    .stroke(AppColors.primary.opacity(0.1), lineWidth: 2)
//                                                    .frame(width: 220, height: 40)
//                                            )
                    
                    HStack {
                        Text("Calorie and macronutrient\nrecommendations")
                            .foregroundStyle(AppColors.primary)
                            .font(.system(size: 16, weight: .semibold, design: .default))
                        
                        Spacer()
                        
                        Button {
                            showChangeTarget = true
                        } label: {
                            AppImages.ButtonIcons.Pen.darkPen
                        }
                    }
                    .padding(.vertical, 32)
                    .padding(.horizontal, 20)
                    
                    HStack(spacing: 16) {
                        NutrientsCard(value: current.dailyCalories, title: "Calories",       color: AppColors.customRed)
                        NutrientsCard(value: current.carbs,         title: "Carbohydrates",  color: AppColors.customOrange)
                    }
                    .padding(.bottom, 4)
                    
                    HStack(spacing: 16) {
                        NutrientsCard(value: current.protein, title: "Proteins", color: AppColors.customBlue)
                        NutrientsCard(value: current.fat,     title: "Fats",     color: AppColors.customGreen)
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
            .scrollIndicators(.hidden)
            .navigationBarBackButtonHidden(true)
            .background(AppColors.background.ignoresSafeArea())
            .animation(
                .easeInOut(duration: 0.2),
                value: [current.dailyCalories, current.protein, current.carbs, current.fat] 
            )
            .safeAreaInset(edge: .bottom) {
                StickyCTA(title: "Next") {
                    hasOnboarded = true
                    paywall.presentInitial()
                }
            }
            .navigationDestination(isPresented: $showChangeTarget) {
                ChangeTargetView(
                    initialCalories: current.dailyCalories,
                    initialProteins: current.protein,
                    initialCarbs:    current.carbs,
                    initialFats:     current.fat
                ) { cal, prot, carbs, fats in
                    await vm.saveManualPlan(
                        calories: cal,
                        proteins: prot,
                        carbs:    carbs,
                        fats:     fats
                    )
                }
            }
            
        
                .onChange(of: hasOnboarded) { new in
                    if new { dismiss() }
                }
    }
}

extension PlanScreen {
    init(plan: PersonalPlan, goalCaption: String = "Maintain weight", onNext: (() -> Void)? = nil) {
        self.plan = plan
        self.goalCaption = goalCaption
        self.onNext = onNext
    }
}

extension Goal {
    var caption: String {
        switch self {
        case .lose: return "Lose weight"
        case .gain: return "Gain weight"
        case .maintain: return "Maintain weight"
        }
    }
}


#Preview {
    NavigationStack {
        PlanScreen(plan: .preview)
    }
}


