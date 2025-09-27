//
//  GoalStep.swift
//  SnapAI
//
//  Created by Isa Melsov on 23/9/25.
//

import SwiftUI

//MARK: - GoalStep
struct GoalStep: View {
    @State private var path = NavigationPath()
    @ObservedObject var vm: OnboardingViewModel

    // ✅ инициализируем из VM (или .lose по умолчанию)
    @State private var selected: Goal
    @State private var desiredWeightText: String

    init(vm: OnboardingViewModel) {
        self.vm = vm
        let initialGoal: Goal = vm.data.goal ?? .lose
        _selected = State(initialValue: initialGoal)

        // если в VM уже есть желаемый вес — подставим в поле
        if let w = vm.data.desiredWeight, w > 0 {
            // без лишних нулей: 72.0 -> "72", 72.5 -> "72.5"
            _desiredWeightText = State(initialValue: w.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(w)) : String(w))
        } else {
            _desiredWeightText = State(initialValue: "")
        }
    }

    var body: some View {
        VStack(spacing: 16) {

            Text("Goal")
                .font(.system(size: 24, weight: .regular))
                .foregroundStyle(AppColors.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 26)

            // картинка по полу
            vm.data.genderImage
                .resizable()
                .scaledToFit()
                .frame(height: 220)

            HStack(spacing: 6) {
                goalButton(.lose,     title: "Lose weight")
                goalButton(.gain,     title: "Gain weight")
                goalButton(.maintain, title: "Maintain weight")
            }
            .padding([.horizontal, .vertical], 26)

            Spacer()

            // желаемый вес (юниты берутся из vm.data.unit)
            UnitTextField(vm: vm,
                          placeholder: "Enter your desired weight",
                          text: $desiredWeightText,
                          kind: .weight)
            .padding(.horizontal, 26)
            .onChange(of: desiredWeightText) { v in
                vm.data.desiredWeight = v.replacingOccurrences(of: ",", with: ".").doubleValue
            }

            Spacer()

            NavigationLink {
                RateStep(vm: vm, path: $path)
            } label: {
                Text("Next")
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 56)
                    .foregroundColor(.white)
                    .background(AppColors.secondary)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
            }
            .simultaneousGesture(TapGesture().onEnded { vm.saveDraft() })
            .padding(.horizontal, 26)
            .padding(.bottom, 28)
        }
        .hideKeyboardOnTap()
        .padding(.top, 8)
        .background(AppColors.background.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) { BackButton() }
            ToolbarItem(placement: .principal) {
                ProgressView(value: 5.0, total: 5.0)
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
        .onAppear {
            // ✅ фиксируем стартовый выбор в VM, чтобы кнопка была «уже нажатой»
            vm.data.goal = selected
        }
    }

    // MARK: - UI helpers

    @ViewBuilder
    private func goalButton(_ goal: Goal, title: String) -> some View {
        let isSelected = (selected == goal)

        Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                selected = goal
                vm.data.goal = goal
            }
        } label: {
            Text(title)
                .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .white : AppColors.primary)
                .frame(maxWidth: .infinity, minHeight: 40)
                .background(isSelected ? AppColors.primary : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(AppColors.primary, lineWidth: 1)
                )
                .shadow(color: .black.opacity(isSelected ? 0.0 : 0.15), radius: 3, y: 2)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    GoalStepPreview()
}

private struct GoalStepPreview: View {
    @StateObject private var vm = OnboardingViewModel(
        repository: LocalRepository(),
        onFinished: {}
    )
    var body: some View {
        NavigationStack {
            GoalStep(vm: vm)
        }
    }
}
