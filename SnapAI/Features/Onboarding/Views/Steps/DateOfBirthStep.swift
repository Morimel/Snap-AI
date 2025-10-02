//
//  DateOfBirthStep.swift
//  SnapAI
//
//  Created by Isa Melsov on 23/9/25.
//

import SwiftUI

//MARK: - DateOfBirthStep
struct DateOfBirthStep: View {
    @ObservedObject var vm: OnboardingViewModel

   
    enum Mode {
        case onboarding
        case picker(initial: Date?, onSelect: (String) -> Void)
    }
    var mode: Mode = .onboarding

    @Environment(\.dismiss) private var dismiss

    @State private var selectedDate: Date

    init(vm: OnboardingViewModel, mode: Mode = .onboarding) {
            self.vm = vm
            self.mode = mode

            // дефолт: −25 лет и 15 число
            let cal  = Calendar.current
            let base = cal.date(byAdding: .year, value: -25, to: Date()) ?? Date()
            let def  = cal.date(bySetting: .day, value: 15, of: base) ?? base

            // 👇 вот этот блок
            var initial = (vm.data.birthDate ?? def).atNoon()
            if case let .picker(initial: initialDate, onSelect: _) = mode, let d = initialDate {
                initial = d.atNoon()
            }
            _selectedDate = State(initialValue: initial)
        }

    var body: some View {
        VStack {
            Text("Date of birth")
                .font(.system(size: 24, weight: .regular))
                .foregroundStyle(AppColors.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 40)

            Spacer()

            DateWheelPicker(selected: $selectedDate)
            
            Spacer()

            switch mode {
            case .onboarding:
                NavigationLink(destination: LifestyleStep(vm: vm)) {
                    Text("Next")
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 60)
                        .foregroundColor(.white)
                        .background(AppColors.secondary)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                }
                .simultaneousGesture(TapGesture().onEnded {
                                    vm.data.birthDate = selectedDate
                                    vm.saveDraft()
                                })
                .padding(.horizontal, 40)
                .padding(.bottom, 28)

            case .picker(initial: _, onSelect: let onSelect):
                Button {
                    vm.data.birthDate = selectedDate
                    let ageString = makeAgeString(from: selectedDate)
                    onSelect(ageString)
                    dismiss()
                } label: {
                    Text("Choose")
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 60)
                        .foregroundColor(.white)
                        .background(AppColors.secondary)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 28)
            }
        }
        .padding()
        .background(AppColors.background.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) { BackButton() }

            ToolbarItem(placement: .principal) {
                switch mode {
                case .onboarding:
                    ProgressView(value: 3, total: 5)
                        .progressViewStyle(
                            ThickLinearProgressViewStyle(
                                height: 10, cornerRadius: 7,
                                fillColor: AppColors.primary, trackColor: AppColors.secondary
                            )
                        )
                        .frame(width: UIScreen.main.bounds.width * 0.6, height: 10)
                        .padding(.top, 2)

                case .picker:
                    Text("Select date of birth")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(AppColors.primary)
                }
            }
        }
    }

    private func makeAgeString(from date: Date) -> String {
        let years = Calendar.current.dateComponents([.year], from: date, to: Date()).year ?? 0
        return "\(max(0, years)) years old"
    }
}

#Preview {
    DateOfBirthStepPreview()
}

private struct DateOfBirthStepPreview: View {
    @StateObject private var vm = OnboardingViewModel(
        repository: LocalRepository(),
        onFinished: {}
    )
    var body: some View {
        NavigationStack {
            DateOfBirthStep(vm: vm)
        }
    }
}


