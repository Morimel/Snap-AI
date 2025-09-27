//
//  GenderStep.swift
//  SnapAI
//
//  Created by Isa Melsov on 23/9/25.
//

import SwiftUI

// MARK: - GenderStep
struct GenderStep: View {
    @ObservedObject var vm: OnboardingViewModel

    // 🔻 новый режим работы
    enum Mode {
        case onboarding                         // как было: с кнопкой Next
        case picker(onSelect: (Gender) -> Void) // как «экран выбора»: без Next, авто-pop
    }
    var mode: Mode = .onboarding

    @State private var selected: Gender = .male
    @State private var currentImage = AppImages.Gender.male

    init(vm: OnboardingViewModel, mode: Mode = .onboarding) {
        self.vm = vm
        self.mode = mode
        let initial = vm.data.gender ?? .male
        _selected = State(initialValue: initial)
        _currentImage = State(initialValue: GenderStep.image(for: initial))
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("Select your gender")
                .font(.system(size: 24, weight: .regular))
                .foregroundStyle(AppColors.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 26)

            currentImage
                .resizable()
                .scaledToFit()
                .frame(height: 300)
                .padding(.top, -8)

            HStack(spacing: 16) {
                genderButton(.male, title: "Male")
                genderButton(.female, title: "Female")
            }
            .padding(.horizontal, 26)

            genderButton(.other, title: "Other")
                .padding(.horizontal, 26)

            Spacer()

            // 🔻 кнопка Next только в онбординге
            if case .onboarding = mode {
                NavigationLink(destination: WeightHeightStep(vm: vm)) {
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
        }
        .background(AppColors.background.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .principal) {
                switch mode {
                case .onboarding:
                    ProgressView(value: 2, total: 5)
                        .progressViewStyle(
                            ThickLinearProgressViewStyle(
                                height: 10, cornerRadius: 7,
                                fillColor: AppColors.primary, trackColor: AppColors.secondary
                            )
                        )
                        .frame(width: UIScreen.main.bounds.width * 0.6, height: 10)
                        .padding(.top, 2)

                case .picker:
                    Text("Select gender")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(AppColors.primary)
                }
            }
        }
        .onAppear {
            // фиксируем начальный выбор
            vm.data.gender = selected
        }
    }

    // MARK: - UI helpers
    @ViewBuilder
    private func genderButton(_ gender: Gender, title: String) -> some View {
        let selectedState = (selected == gender)

        Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                selected = gender
                vm.data.gender = gender
                currentImage = GenderStep.image(for: gender)
            }
        } label: {
            Text(title)
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(selectedState ? .white : AppColors.text)
                .frame(maxWidth: .infinity, minHeight: 60)
                .background(selectedState ? AppColors.secondary : Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppColors.secondary, lineWidth: 1)
                )
                .shadow(color: .black.opacity(selectedState ? 0.0 : 0.15), radius: 3, y: 2)
        }
    }

    private static func image(for g: Gender) -> Image {
        switch g {
        case .male:   return AppImages.Gender.male
        case .female: return AppImages.Gender.female
        case .other:  return AppImages.Gender.other
        }
    }
}


#Preview {
    GenderStepPreview()
}

private struct GenderStepPreview: View {
    @StateObject private var vm = OnboardingViewModel(
        repository: LocalRepository(),
        onFinished: {}
    )
    var body: some View {
        NavigationStack {
            GenderStep(vm: vm)
        }
    }
}
