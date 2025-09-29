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
    
    @Environment(\.dismiss) private var dismiss
    
    enum Mode {
            case onboarding
            case picker
        }
        var mode: Mode = .onboarding
    
        @State private var saving = false
        @State private var error: String?

    init(vm: OnboardingViewModel, mode: Mode = .onboarding) {
            self.vm = vm
            self.mode = mode

            let initialGoal: Goal = vm.data.goal ?? .lose
            _selected = State(initialValue: initialGoal)

            if let w = vm.data.desiredWeight, w > 0 {
                let s = (w.truncatingRemainder(dividingBy: 1) == 0) ? String(Int(w)) : String(w)
                _desiredWeightText = State(initialValue: s)
            } else {
                _desiredWeightText = State(initialValue: "")
            }
        }
    
    @State private var showSnack = false
    @State private var snackText = "Saved"

    var body: some View {
        VStack(spacing: 16) {
            
            if let error {
                            Text(error).foregroundColor(.red).padding(.horizontal, 26)
                        }

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
                            // в онбординге можно обновлять live, в picker мы коммитим при Save
                            if case .onboarding = mode {
                                vm.data.desiredWeight = v.replacingOccurrences(of: ",", with: ".").doubleValue
                            }
                        }

            Spacer()

            switch mode {
                        case .onboarding:
                            NavigationLink(destination: RateStep(vm: vm)) {
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

                        case .picker:
                            Button {
                                Task { await saveAndClose() }
                            } label: {
                                Text(saving ? "Saving..." : "Save")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity, minHeight: 56)
                                    .foregroundColor(.white)
                                    .background(AppColors.secondary)
                                    .clipShape(RoundedRectangle(cornerRadius: 18))
                            }
                            .disabled(saving)
                            .padding(.horizontal, 26)
                            .padding(.bottom, 28)
                        }
        }
        .hideKeyboardOnTap()
        .padding(.top, 8)
        .background(AppColors.background.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .overlay(alignment: .bottom) {
            if showSnack {
                SnackBarView(text: "Saved")
            }
        }

        .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) { BackButton() }

                    ToolbarItem(placement: .principal) {
                        switch mode {
                        case .onboarding:
                            ProgressView(value: 5.0, total: 5.0)
                                .progressViewStyle(
                                    ThickLinearProgressViewStyle(
                                        height: 10, cornerRadius: 7,
                                        fillColor: AppColors.primary, trackColor: AppColors.secondary
                                    )
                                )
                                .frame(width: UIScreen.main.bounds.width * 0.6, height: 10)
                                .padding(.top, 2)
                        case .picker:
                            Text("Change goal")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundStyle(AppColors.primary)
                        }
                    }
                }
        .onAppear {
            // ✅ фиксируем стартовый выбор в VM, чтобы кнопка была «уже нажатой»
            vm.data.goal = selected
        }
    }
    
    // MARK: - Save for picker mode
        private func saveAndClose() async {
            await MainActor.run { saving = true; error = nil }

            // Коммитим выбор в VM
            vm.data.goal = selected
            let txt = desiredWeightText.replacingOccurrences(of: ",", with: ".")
            let val = Double(txt)
            if selected == .maintain {
                vm.data.desiredWeight = nil   // для maintain целевой вес не обязателен
            } else {
                vm.data.desiredWeight = val
            }

            do {
                try await AuthAPI.shared.updateProfile(from: vm.data) // внутри шлёт Notification.profileDidChange

                await MainActor.run {
                    saving = false
                    // haptic
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    // snackbar
                    snackText = "Saved"
                    withAnimation { showSnack = true }
                }

                // подождать чуть-чуть, закрыть экран и спрятать snackbar
                Task {
                    try? await Task.sleep(nanoseconds: 1_600_000_000)
                    await MainActor.run {
                        withAnimation { showSnack = false }
                        dismiss()
                    }
                }
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                    self.saving = false
                }
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
