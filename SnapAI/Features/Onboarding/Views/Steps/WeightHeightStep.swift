//
//  WeightHeightStep.swift
//  SnapAI
//
//  Created by Isa Melsov on 23/9/25.
//

import SwiftUI

//MARK: - WeightHeightStep
struct WeightHeightStep: View {
    @ObservedObject var vm: OnboardingViewModel

    enum Mode {
        case onboarding
        case picker(onSelect: (_ heightDisplay: String, _ weightDisplay: String) -> Void)
    }

    var mode: Mode = .onboarding

    @Environment(\.dismiss) private var dismiss

    @State private var weightText = ""
    @State private var heightText = ""
    @State private var didBootstrap = false

    init(vm: OnboardingViewModel, mode: Mode = .onboarding) {
        self.vm = vm
        self.mode = mode
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("Weight and Height")
                .font(.system(size: 24, weight: .regular))
                .foregroundStyle(AppColors.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 26)

            Spacer()

            BubbleSegmentedControl(vm: vm, height: 48)
                .padding(.horizontal, 26)

            Text("Weight")
                .font(.system(size: 24, weight: .regular))
                .foregroundStyle(AppColors.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 26)

            UnitTextField(vm: vm, placeholder: "Your weight", text: $weightText, kind: .weight)
                .padding(.horizontal, 26)

            Text("Height")
                .font(.system(size: 24, weight: .regular))
                .foregroundStyle(AppColors.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 26)

            UnitTextField(vm: vm, placeholder: "Your height", text: $heightText, kind: .height)
                .padding(.horizontal, 26)

            Spacer()

            if case .onboarding = mode {
                NavigationLink(destination: DateOfBirthStep(vm: vm)) {
                    Text("Next")
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 60)
                        .foregroundColor(.white)
                        .background(AppColors.secondary)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                }
                .padding(.horizontal, 26)
                .padding(.bottom, 28)
            } else if case let .picker(onSelect) = mode {
                Button {
                    let w = Double(weightText.replacingOccurrences(of: ",", with: "."))
                    let h = Double(heightText.replacingOccurrences(of: ",", with: "."))
                    vm.data.weight = w
                    vm.data.height = h

                    let weightDisplay = formatWeight(w, unit: vm.data.unit)
                    let heightDisplay = formatHeight(h, unit: vm.data.unit)

                    onSelect(heightDisplay, weightDisplay)
                    dismiss()
                } label: {
                    Text("Choose")
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
        .hideKeyboardOnTap()
        .padding()
        .background(AppColors.background.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) { BackButton() }
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
                    Text("Weight & Height")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(AppColors.primary)
                }
            }
        }
        .task {
            guard !didBootstrap else { return }
            didBootstrap = true
            // НЕ форсить imperial — оставить как есть
            if let w = vm.data.weight { weightText = String(format: "%.0f", w) }
            if let h = vm.data.height { heightText = String(format: "%.0f", h) }
        }
        .onChange(of: weightText) { s in
            let sanitized = s.replacingOccurrences(of: ",", with: ".")
            let newVal = Double(sanitized)
            if vm.data.weight != newVal {
                vm.data.weight = newVal
            }
        }
        .onChange(of: heightText) { s in
            let sanitized = s.replacingOccurrences(of: ",", with: ".")
            let newVal = Double(sanitized)
            if vm.data.height != newVal {
                vm.data.height = newVal
            }
        }
        .onDisappear {
            guard case .picker = mode else { return }
            let w = Double(weightText.replacingOccurrences(of: ",", with: "."))
            let h = Double(heightText.replacingOccurrences(of: ",", with: "."))
            if vm.data.weight != w { vm.data.weight = w }
            if vm.data.height != h { vm.data.height = h }
        }
    }

    // MARK: - Formatting helpers

    private func formatWeight(_ w: Double?, unit: UnitSystem) -> String {
        guard let w else { return "—" }
        switch unit {
        case .imperial: return "\(Int(round(w))) lbs"
        case .metric:   return "\(Int(round(w))) kg"
        }
    }

    private func formatHeight(_ h: Double?, unit: UnitSystem) -> String {
        guard let h else { return "—" }
        switch unit {
        case .imperial:
            let inches = Int(round(h))
            let ft = inches / 12
            let inch = inches % 12
            return "\(ft)'\(inch)\""
        case .metric:
            return "\(Int(round(h))) cm"
        }
    }
}


#Preview {
    WeightHeightStepPreview()
}

private struct WeightHeightStepPreview: View {
    @StateObject private var vm = OnboardingViewModel(
        repository: LocalRepository(),
        onFinished: {}
    )
    var body: some View {
        NavigationStack {
            WeightHeightStep(vm: vm)
        }
    }
}
