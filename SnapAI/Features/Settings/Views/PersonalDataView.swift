//
//  PersonalDataView.swift
//  SnapAI
//
//  Created by Isa Melsov on 23/9/25.
//

import SwiftUI

// MARK: - Personal Data Screen
struct PersonalDataView: View {
    @Binding var gender: String
    @Binding var age: String        // формат: "27 years old"
    @Binding var height: String     // формат: 5'9"
    @Binding var weight: String     // формат: "175 lbs"

    @State private var activeEditor: Editor?

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
                    LabeledPillRow(label: "Gender", value: gender) {
                        activeEditor = .gender
                    }
                    LabeledPillRow(label: "Age", value: age) {
                        activeEditor = .age
                    }
                    LabeledPillRow(label: "Height", value: height) {
                        activeEditor = .height
                    }
                    LabeledPillRow(label: "Weight", value: weight) {
                        activeEditor = .weight
                    }
                }
                .padding(.top, 8)
            }
            .padding(.vertical, 12)
        }
        .background(AppColors.background.ignoresSafeArea())
        .navigationTitle("Personal data")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $activeEditor) { editor in
            switch editor {
            case .gender:
                GenderPickerSheet(value: $gender)
            case .age:
                AgePickerSheet(value: $age)
            case .height:
                HeightPickerSheet(value: $height)
            case .weight:
                WeightPickerSheet(value: $weight)
            }
        }
    }
}

