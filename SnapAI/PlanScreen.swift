//
//  PlanScreen.swift
//  SnapAI
//
//  Created by Isa Melsov on 18/9/25.
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

//MARK: - NutrientsCard
struct NutrientsCard: View {
    let value: Int
    let title: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .center) {
            Text("\(title)")
                .padding(.vertical, 16)
                .foregroundStyle(AppColors.primary)
                .font(.system(size: 18, weight: .regular, design: .default))
            
            ZStack {
                Circle()
                    .stroke(lineWidth: 12)
                    .frame(width: 128, height: 128)
                    .foregroundStyle(color.opacity(0.5))
                
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .frame(width: 128, height: 128)
                    .rotationEffect(.degrees(-90))
                    .foregroundStyle(LinearGradient(gradient: Gradient(colors: [color, color.opacity(0.3)]), startPoint: .topLeading, endPoint: .bottom))
                
                Text("\(value)")
                    .foregroundStyle(AppColors.primary)
                    .font(.system(size: 24, weight: .bold, design: .default))
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 4)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(AppColors.primary.opacity(0.2), lineWidth: 2)
            )
        
        
    }
}


//MARK: - HelpfulTipsCard
struct HelpfulTipsCard: View {
    let tips: [Tip]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(tips.indices, id: \.self) { i in
                TipRow(tip: tips[i])
                    .padding()
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(.white))
        .overlay(RoundedRectangle(cornerRadius: 16)
            .stroke(AppColors.primary.opacity(0.12), lineWidth: 1))
        .shadow(color: .black.opacity(0.06), radius: 10, y: 4)
    }
}


//MARK: - TipRow
struct TipRow: View {
    let tip: Tip

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            tip.image
                .resizable()
                .scaledToFit()
                .frame(width: 56, height: 56)
                .padding()
                .accessibilityHidden(true)


            VStack(alignment: .leading, spacing: 6) {
                Text(tip.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppColors.primary)

                Text(tip.subtitle)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(AppColors.primary)
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

//MARK: - Tip
struct Tip {
    let image: Image
    let title: String
    let subtitle: String
}


//MARK: - BulletListBox
struct BulletListBox: View {
    let title: String
    let items: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(AppColors.primary)

            VStack(alignment: .leading, spacing: 16) {
                ForEach(items, id: \.self) { text in
                    BulletRow(text: text)
                }
            }
            .padding(14)
        }
    }
}


//MARK: - BulletRow
private struct BulletRow: View {
    let text: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text("•")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(AppColors.primary)
                .padding(.top, 2) // чуть опустить, чтобы по базовой линии красиво

            // текст с переносами и ровным отступом
            Text(text)
                .font(.system(size: 15))
                .foregroundStyle(AppColors.primary)
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.leading)
                .lineSpacing(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}


//MARK: - PersonalPlan
extension PersonalPlan {
    static let preview: PersonalPlan = .init(
        weightUnit: "lbs",
        maintainWeight: 121,
        dailyCalories: 2000,
        protein: 140,
        fat: 70,
        carbs: 180,
        meals: [
            .init(time: "08:30", title: "Овсянка с ягодами", kcal: 420),
            .init(time: "13:00", title: "Курица + рис + салат", kcal: 620),
            .init(time: "17:00", title: "Творог + яблоко", kcal: 280),
            .init(time: "20:00", title: "Лосось + гречка + овощи", kcal: 620),
        ],
        workouts: [
            .init(day: "Пн", focus: "Грудь/трицепс", durationMin: 45),
            .init(day: "Ср", focus: "Спина/бицепс", durationMin: 45),
            .init(day: "Пт", focus: "Ноги/кор", durationMin: 50),
        ]
    )
}


//MARK: - StickyCTA
struct StickyCTA: View {
    let title: String
    let action: () -> Void

    var body: some View {
        // фон области инсета + сама кнопка
        ZStack {
            // фон «под кнопкой», как на скрине
            Color(.white)
                .overlay(Divider().opacity(0.0), alignment: .top) // тонкая разделительная линия (optional)

            Button(action: action) {
                Text(title)
                    .font(.system(size: 20, weight: .semibold))
                    .frame(maxWidth: .infinity, minHeight: 60)
                    .foregroundColor(.white)
                    .background(AppColors.secondary)
                    .clipShape(RoundedRectangle(cornerRadius: 22))
            }
            .padding(.horizontal, 20)
        }
        .ignoresSafeArea(edges: .bottom)
        .frame(height: 88)// держим до самого края
    }
}


#Preview {
    NavigationStack {
           PlanScreen(plan: .preview)
       }
//    NutrientsCard(planUnit: .preview, title: "Calories", color: AppColors.customRed)
}
