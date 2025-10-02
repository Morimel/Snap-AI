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

    @State private var selected: Goal
    @State private var desiredWeightText: String
    
    @Environment(\.dismiss) private var dismiss
    
    private var unitLabel: String { vm.data.unit == .imperial ? "lbs" : "kg" }
    
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

            /// картинка по полу
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

            UnitTextField(vm: vm,
                          placeholder: selected == .maintain
                                              ? "Your current weight (\(unitLabel))"
                                              : "Enter your desired weight",
                          text: $desiredWeightText,
                          kind: .weight)
            .padding(.horizontal, 26)
            .disabled(selected == .maintain)
            .opacity(selected == .maintain ? 0.6 : 1.0)
            .onChange(of: desiredWeightText) { v in
                guard selected != .maintain else { return }
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
                .simultaneousGesture(TapGesture().onEnded {
                    // ✅ коммитим в VM перед сохранением драфта
                    vm.data.goal = selected
                    let txt = desiredWeightText.replacingOccurrences(of: ",", with: ".")
                    vm.data.desiredWeight = (selected == .maintain) ? nil : Double(txt)
                    vm.saveDraft()
                })


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
                    // подтягиваем актуальные значения из vm.data
                    selected = vm.data.goal ?? .lose

                    if selected == .maintain {
                        // показываем ТЕКУЩИЙ вес
                        if let w = vm.data.weight {
                            desiredWeightText = formatWeight(w)
                        } else {
                            desiredWeightText = ""
                        }
                        vm.data.desiredWeight = nil
                    } else {
                        // показываем ЦЕЛЕВОЙ вес
                        if let w = vm.data.desiredWeight, w > 0 {
                            desiredWeightText = formatWeight(w)
                        } else {
                            desiredWeightText = ""
                        }
                    }
                }
        .onChange(of: selected) { new in
                    if new == .maintain {
                        // при переключении на maintain — отобразим текущий вес, target убираем
                        if let w = vm.data.weight {
                            desiredWeightText = formatWeight(w)
                        } else {
                            desiredWeightText = ""
                        }
                        vm.data.desiredWeight = nil
                    } else {
                        // при переключении на lose/gain — вернём прежнее значение target (если было)
                        if let w = vm.data.desiredWeight, w > 0 {
                            desiredWeightText = formatWeight(w)
                        } else {
                            desiredWeightText = ""
                        }
                    }
                }


    }
    
    private func formatWeight(_ w: Double) -> String {
            (w.truncatingRemainder(dividingBy: 1) == 0) ? String(Int(w)) : String(w)
        }
    
    // MARK: - Save for picker mode
        private func saveAndClose() async {
            await MainActor.run { saving = true; error = nil }

            // Коммитим выбор в VM
            vm.data.goal = selected
            let txt = desiredWeightText.replacingOccurrences(of: ",", with: ".")
            let val = Double(txt)
            if selected == .maintain {
                vm.data.desiredWeight = nil
            } else {
                vm.data.desiredWeight = val
            }

            do {
                print("PATCH goal =", vm.data.goal?.apiValue ?? "nil")
                try await AuthAPI.shared.updateProfile(from: vm.data)
                
                if let id = UserStore.id() {
                        let p = try await AuthAPI.shared.getProfile(id: id)
                        await MainActor.run { vm.data.fill(from: p) }   // у тебя есть fill(from:)
                    }

                await MainActor.run {
                    saving = false
                    /// haptic
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    /// snackbar
                    snackText = "Saved"
                    withAnimation { showSnack = true }
                }

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
