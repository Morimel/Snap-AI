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
        case picker(onSelect: (String) -> Void)   // вернём строку вроде "27 years old"
    }
    var mode: Mode = .onboarding

    @Environment(\.dismiss) private var dismiss

    // дефолт ~25 лет назад; подставь свою логику если нужно
    @State private var selectedDate: Date =
        Calendar.current.date(byAdding: .year, value: -25, to: Date()) ?? Date()

    var body: some View {
        VStack {
            Text("Date of birth")
                .font(.system(size: 24, weight: .regular))
                .foregroundStyle(AppColors.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 40)

            Spacer()

            // Если твой DateWheelPicker поддерживает биндинг – лучше так:
            // DateWheelPicker(selected: $selectedDate)
            DateWheelPicker()

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
                .padding(.horizontal, 40)
                .padding(.bottom, 28)

            case .picker(let onSelect):
                Button {
                    let ageString = makeAgeString(from: selectedDate)
                    // при желании ещё и в модель: vm.data.birthDate = selectedDate
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
                    // 🔸 прогресс-бар в онбординге
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
                    // 🔸 обычный заголовок в режиме выбора
                    Text("Select date of birth")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(AppColors.primary)
                }
            }
        }
        .onAppear {
            // если дата уже в модели — подхватить:
            // if let d = vm.data.birthDate { selectedDate = d }
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
            DateOfBirthStep(vm: vm) // .onboarding по умолчанию
        }
    }
}


