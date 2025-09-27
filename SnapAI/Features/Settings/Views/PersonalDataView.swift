//
//  PersonalDataView.swift
//  SnapAI
//
//  Created by Isa Melsov on 23/9/25.
//

import SwiftUI

// MARK: - Personal Data Screen
struct PersonalDataView: View {
    @ObservedObject var vm: OnboardingViewModel
    @Binding var gender: String
    @Binding var age: String
    @Binding var height: String
    @Binding var weight: String
    
    @Environment(\.dismiss) private var dismiss   // 👈 добавили
    
    @State private var activeEditor: Editor?
    @State private var goGenderPicker = false

    enum Editor: Identifiable {
        case gender, age, height, weight
        var id: Int { hashValue }
        var title: String {
            switch self {
            case .gender: return "Gender"
            case .age:    return "Age"
            case .height: return "Height"
            case .weight: return "Weight"
            }
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                SectionCard {
                    NavigationLink {
                            GenderStep(
                                vm: vm,
                                mode: .picker { g in
                                    gender = g.displayName
                                    vm.data.gender = g
                                }
                            )
                        } label: {
                            LabeledPillRow(label: "Gender", value: gender)   // ⬅️ без action
                        }
                    // ⬇️ Age -> DateOfBirthStep
                    NavigationLink {
                        DateOfBirthStep(
                            vm: vm,
                            mode: .picker { ageString in
                                age = ageString
                                // при желании: vm.data.ageYears = ...
                            }
                        )
                        .navigationTitle("Date of birth")
                        .navigationBarTitleDisplayMode(.inline)
                    } label: {
                        LabeledPillRow(label: "Age", value: age)
                    }


                       // ⬇️ Height -> WeightHeightStep
                    // ⬇️ объединённая строка
                    NavigationLink {
                        WeightHeightStep(
                            vm: vm,
                            mode: .picker { heightDisplay, weightDisplay in
                                height = heightDisplay
                                weight = weightDisplay
                            }
                        )
                        .navigationTitle("Weight & Height")
                        .navigationBarTitleDisplayMode(.inline)
                    } label: {
                        LabeledPillRow(label: "Height & Weight", value: "\(height) • \(weight)")
                    }

                }
                .padding(.top, 8)
            }
            .padding(.vertical, 12)
        }
        .hideKeyboardOnTap()
        .navigationBarBackButtonHidden(true)
        .toolbar {
            // ЛЕВАЯ КНОПКА НАЗАД
            ToolbarItem(placement: .topBarLeading) {
                Button(action: { dismiss() }) {    // 👈 pop текущего экрана
                    AppImages.ButtonIcons.arrowRight
                        .resizable()
                        .scaledToFill()
                        .frame(width: 12, height: 12)
                        .rotationEffect(.degrees(180))
                        .padding(12)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            
            // ЗАГОЛОВОК ПО ЦЕНТРУ
            ToolbarItem(placement: .principal) {
                Text("Change target")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(AppColors.primary)
            }
        }
        .background(AppColors.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        let vm = OnboardingViewModel(repository: LocalRepository(), onFinished: {})
        PersonalDataView(
            vm: vm,
            gender: .constant("Female"),
            age:    .constant("27 years old"),
            height: .constant("5'9\""),
            weight: .constant("175 lbs")
        )
    }
}


