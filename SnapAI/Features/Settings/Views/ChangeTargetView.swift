//
//  ChangeTargetView.swift
//  SnapAI
//
//  Created by Isa Melsov on 24/9/25.
//

import SwiftUI

struct ChangeTargetView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var calories = 1958
    @State private var proteins = 50
    @State private var carbohydrates = 150
    @State private var fats = 32

    // 🔹 общий фокус для всех полей
    @FocusState private var focusedField: Field?

    enum Field: Hashable { case calories, proteins, carbs, fats }

    var body: some View {
        VStack {
            LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: 14) {

                MetricPill(title: "Calories", value: "\(calories) kcal")
                StepperPill(
                    title: "Change",
                    value: $calories,
                    field: .calories,
                    focused: $focusedField
                )

                MetricPill(title: "Proteins",
                           value: "\(proteins) g",
                           badge: .init(kind: .text("P"), color: .blue))
                StepperPill(
                    title: "Change",
                    value: $proteins,
                    field: .proteins,
                    focused: $focusedField
                )

                MetricPill(title: "Carbohydrates",
                           value: "\(carbohydrates) g",
                           badge: .init(kind: .text("C"), color: .orange))
                StepperPill(
                    title: "Change",
                    value: $carbohydrates,
                    field: .carbs,
                    focused: $focusedField
                )

                MetricPill(title: "Fats",
                           value: "\(fats) g",
                           badge: .init(kind: .text("F"), color: .green))
                StepperPill(
                    title: "Change",
                    value: $fats,
                    field: .fats,
                    focused: $focusedField
                )
            }
            .padding(.vertical, 20)

            // твоя кнопка Edit…
            Spacer()
        }
        .hideKeyboardOnTap()
        .scrollDismissesKeyboard(.immediately)
        .padding(.horizontal)
        .background(AppColors.background)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button { dismiss() } label: {
                            AppImages.ButtonIcons.arrowRight
                                .resizable().scaledToFill()
                                .frame(width: 12, height: 12)
                                .rotationEffect(.degrees(180))
                                .padding(12)
                        }
                        .buttonStyle(.plain)
                    }
                    ToolbarItem(placement: .principal) {
                        Text("Change target")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(AppColors.primary)
                    }
                }
    }
}


#Preview {
    NavigationStack {
        ChangeTargetView()
    }
}
