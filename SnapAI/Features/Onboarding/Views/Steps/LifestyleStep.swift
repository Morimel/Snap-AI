//
//  LifestyleStep.swift
//  SnapAI
//
//  Created by Isa Melsov on 23/9/25.
//

import SwiftUI

//MARK: - LifestyleStep
import SwiftUI

struct LifestyleStep: View {
    @ObservedObject var vm: OnboardingViewModel

    @State private var selected: Lifestyle
    @State private var currentImage: Image

    // Стартуем с того, что уже в VM (или .sedentary по умолчанию)
    init(vm: OnboardingViewModel) {
        self.vm = vm
        let initial: Lifestyle = vm.data.lifestyle ?? .sedentary   // если не опционал, оставь: vm.data.lifestyle
        _selected     = State(initialValue: initial)
        _currentImage = State(initialValue: LifestyleStep.image(for: initial))
    }

    var body: some View {
        VStack {
            Text("Activity")
                .font(.system(size: 24, weight: .regular))
                .foregroundStyle(AppColors.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 26)

            Spacer()

            currentImage
                .resizable()
                .scaledToFit()
                .frame(height: 220)
                .padding(.vertical)

            VStack(spacing: 16) {
                lifeStyleButton(.sedentary, title: "Sedentary lifestyle")
                lifeStyleButton(.normal,     title: "Normal lifestyle")
                lifeStyleButton(.active,     title: "Active lifestyle")
            }
            .padding([.horizontal, .vertical], 26)

            Spacer()

            NavigationLink(destination: GoalStep(vm: vm)) {
                Text("Next")
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 60)
                    .foregroundColor(.white)
                    .background(AppColors.secondary)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
            }
            .padding(.horizontal, 26)
            .padding(.bottom, 28)
        }
        .padding()
        .background(AppColors.background.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) { BackButton() }
            ToolbarItem(placement: .principal) {
                ProgressView(value: 4, total: 5)
                    .progressViewStyle(
                        ThickLinearProgressViewStyle(
                            height: 10, cornerRadius: 7,
                            fillColor: AppColors.primary, trackColor: AppColors.secondary
                        )
                    )
                    .frame(width: UIScreen.main.bounds.width * 0.6, height: 10)
                    .padding(.top, 2)
            }
        }
        .onAppear { vm.data.lifestyle = selected } // фиксируем выбор в модели
    }

    // MARK: - UI

    @ViewBuilder
    private func lifeStyleButton(_ lifeStyle: Lifestyle, title: String) -> some View {
        let isSelected = (selected == lifeStyle)

        Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                selected = lifeStyle
                vm.data.lifestyle = lifeStyle
                currentImage = LifestyleStep.image(for: lifeStyle)
            }
        } label: {
            Text(title)
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(isSelected ? .white : AppColors.text)
                .frame(maxWidth: .infinity, minHeight: 60)
//                .background(isSelected ? AppColors.secondary : .clear)
                .background(isSelected ? AppColors.secondary : Color.white.opacity(0.001))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppColors.secondary, lineWidth: 1)
                )
                .shadow(color: .black.opacity(isSelected ? 0 : 0.15), radius: 3, y: 2)
        }
        .buttonStyle(.plain)
        .contentShape(RoundedRectangle(cornerRadius: 12))   // ← ВЕСЬ блок теперь тапаемый
    }


    private static func image(for lifestyle: Lifestyle) -> Image {
        switch lifestyle {
        case .sedentary: return AppImages.Activity.sedantary   // ← как у тебя назван ассет
        case .normal:    return AppImages.Activity.normal
        case .active:    return AppImages.Activity.active
        }
    }
}

#Preview {
    LifestyleStepPreview()
}


private struct LifestyleStepPreview: View {
    @StateObject private var vm = OnboardingViewModel(
        repository: LocalRepository(),
        onFinished: {}
    )
    var body: some View {
        NavigationStack {
            LifestyleStep(vm: vm)
        }
    }
}
