//
//  MealEditSheet.swift
//  SnapAI
//
//  Created by Isa Melsov on 23/9/25.
//

import SwiftUI

//MARK: - MealEditSheet
struct MealEditSheet: View {
    @ObservedObject var vm: MealViewModel
    @Binding var isPresented: Bool

    @State private var draft = Meal()

    var body: some View {
        VStack(spacing: 16) {
            grabber

            Text("Edit mode")
                .font(.title2.weight(.semibold))

            ScrollView {
                form
            }

            Button("Сохранить") {
                vm.meal = draft
                withAnimation(.spring(response: 0.32, dampingFraction: 0.9)) { isPresented = false }
            }
            .buttonStyle(CapsuleButtonStyle(background: Color(.systemGreen),
                                             foreground: .white))
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .background(Color(.systemMint).opacity(0.12).ignoresSafeArea())
        .onAppear { draft = vm.meal }
        .gesture(
            DragGesture().onEnded { value in
                if value.translation.height > 100 {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.9)) { isPresented = false }
                }
            }
        )
    }

    // MARK: - Subviews

    private var grabber: some View {
        Capsule()
            .frame(width: 44, height: 5)
            .foregroundStyle(Color.secondary.opacity(0.3))
            .padding(.top, 8)
    }

    private var form: some View {
        VStack(alignment: .leading, spacing: 16) {
            TextField("Meal name", text: $draft.title)
                .padding()
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            HStack(spacing: 12) {
                metricField(title: "Calories", value: $draft.calories, unit: "kcal")
                metricField(title: "Fats", value: $draft.fats, unit: "g")
            }

            HStack(spacing: 12) {
                metricField(title: "Proteins", value: $draft.proteins, unit: "g")
                metricField(title: "Carbohydrates", value: $draft.carbs, unit: "g")
            }

            Text("Ingredients")
                .font(.title3.weight(.semibold))

            IngredientList(ingredients: $draft.ingredients)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
}

private func metricField(title: String, value: Binding<Int>, unit: String) -> some View {
    VStack(alignment: .leading, spacing: 6) {
        Text(title).font(.caption).foregroundColor(.secondary)
        HStack {
            TextField("0", text: Binding(
                get: { String(value.wrappedValue) },
                set: { value.wrappedValue = Int($0.filter(\.isNumber)) ?? 0 }
            ))
            .keyboardType(.numberPad)
            Spacer()
            Text(unit).foregroundColor(.secondary)
        }
        .padding(.vertical, 12).padding(.horizontal, 14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
