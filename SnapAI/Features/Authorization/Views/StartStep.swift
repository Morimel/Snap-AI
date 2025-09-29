//
//  StartStep.swift
//  SnapAI
//
//  Created by Isa Melsov on 23/9/25.
//
import SwiftUI

struct StartStep: View {
    @ObservedObject var vm: OnboardingViewModel
    @EnvironmentObject private var router: OnboardingRouter
    @State private var focalYOffset: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ZStack {
                    AppImages.OtherImages.food1
                        .resizable()
                        .scaledToFill()
                        .frame(height: geo.size.height * 1.1)
                        .clipped()
                        .offset(y: focalYOffset)

                    FocusSquare().offset(y: -130)
                    
                    NutrientChipsCluster()
                        .offset(y: -140)
                }

                VStack(spacing: 16) {
                    Spacer()
                    (Text("Welcome to ").fontWeight(.regular).foregroundColor(AppColors.primary)
                     + Text("Snap AI").fontWeight(.bold).foregroundColor(AppColors.primary))
                        .font(.system(size: 36))
                    Spacer()

                    Text("Count calories from a photo in just 1 click")
                        .multilineTextAlignment(.center)
                        .foregroundColor(AppColors.text)
                    
                    Button {
                        router.push(.meeting)
                    } label: {
                        Text("Get Started")
                            .font(.headline)
                            .frame(maxWidth: .infinity, minHeight: 56)
                            .foregroundStyle(.white)
                            .background(AppColors.secondary)
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                    }
                    .padding(.bottom, 28)

                    
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
                .frame(height: geo.size.height * 0.42)
                .frame(maxWidth: .infinity)
                .background(
                    UnevenRoundedRectangle(cornerRadii: .init(topLeading: 28, topTrailing: 28))
                        .fill(AppColors.background)
                        .ignoresSafeArea(edges: .bottom)
                )
                .shadow(color: .black.opacity(0.08), radius: 12, y: -2)
                .offset(y: 8)
                .frame(maxHeight: .infinity, alignment: .bottom)
            }
            .ignoresSafeArea()
        }
    }
}

// MARK: - Reusable chip
struct NutrientChip: View {
    var initial: String
    var valueText: String
    var circleColor: Color
    var circleTextColor: Color = .white

    private let pillBG = AppColors.background

    var body: some View {
        HStack(alignment: .center) {
            ZStack {
                Circle().fill(circleColor)
                    .frame(width: 28, height: 28)
                Text(initial)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(circleTextColor)
            }
            .frame(width: 52, height: 48)

            Text(valueText)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(AppColors.primary)
                .padding(.trailing)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule().fill(pillBG)
        )
    }
}

// MARK: - Composition 
struct NutrientChipsCluster: View {
    var body: some View {
        ZStack {
            Color.clear

            NutrientChip(initial: "P", valueText: "50 g", circleColor: AppColors.customBlue)
                .offset(x: -90, y: -160)

            NutrientChip(initial: "F", valueText: "32 g", circleColor: AppColors.customGreen)
                .offset(x: 88, y: -24)

            NutrientChip(initial: "C", valueText: "150 g", circleColor: AppColors.customOrange)
                .offset(x: -86, y: 28)

            NutrientChip(initial: "K", valueText: "241 kcal", circleColor: AppColors.customRed)
                .offset(x: 76, y: 164)
        }
        .frame(width: 194, height: 252)
    }
}


#Preview {
    NavigationStack {
        StartStep(vm: OnboardingViewModel(repository: LocalRepository(), onFinished: {}))
    }
}
