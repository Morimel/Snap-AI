//
//  StartStep.swift
//  SnapAI
//
//  Created by Isa Melsov on 23/9/25.
//
import SwiftUI

struct StartStep: View {
    @ObservedObject var vm: OnboardingViewModel
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

                    AppImages.OtherImages.weightCards
                        .resizable()
                        .scaledToFit()
                        .frame(height: geo.size.height * 0.5)
                        .clipped()
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

                    NavigationLink(value: OnbRoute.meeting) {
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

    private let pillBG = Color(red: 0.93, green: 0.98, blue: 0.95) // светло-мятный как в примере

    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle().fill(circleColor)
                Text(initial)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(circleTextColor)
            }
            .frame(width: 22, height: 22)

            Text(valueText)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule().fill(pillBG)
        )
    }
}

// MARK: - Composition (как на макете)
struct NutrientChipsCluster: View {
    var body: some View {
        ZStack {
            // размеры холста под картинку из примера
            Color.clear

            // P 50 g (белки)
            NutrientChip(initial: "P", valueText: "50 g", circleColor: .blue)
                .offset(x: -60, y: -95)

            // F 32 g (жиры)
            NutrientChip(initial: "F", valueText: "32 g", circleColor: .green)
                .offset(x: 58, y: -52)

            // C 150 g (углеводы) — буква в кружке тёмная, как в примере
            NutrientChip(initial: "C", valueText: "150 g", circleColor: .yellow, circleTextColor: .black)
                .offset(x: -74, y: 18)

            // K 241 kcal (калории)
            NutrientChip(initial: "K", valueText: "241 kcal", circleColor: .red)
                .offset(x: 10, y: 86)
        }
        .frame(width: 194, height: 252) // под размер рефа
    }
}


#Preview {
    NavigationStack {
        StartStep(vm: OnboardingViewModel(repository: LocalRepository(), onFinished: {}))
    }
}
