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
//            grabber

            Text("Edit mode")
                .foregroundStyle(AppColors.primary)
                .font(.title)

            ScrollView {
                form
                
                
                
                PlusCapsuleButton(width: 140, height: 56, iconSize: 20) {
                    vm.meal = draft
                    print("pluc capsule tapped")
                }
                .padding(.bottom, 16)
                
                
                Button("Сохранить") {
                    vm.meal = draft
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.9)) { isPresented = false }
                }
                .buttonStyle(.plain) // убираем системные артефакты
                .frame(maxWidth: .infinity, minHeight: 56)
                .background(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(AppColors.secondary)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(AppColors.primary.opacity(0.10), lineWidth: 1)
                )
                .overlay(
                    // верхняя мягкая подсветка
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(.white.opacity(0.9), lineWidth: 1)
                        .blendMode(.overlay)
                        .offset(y: -1)
                        .mask(
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .fill(LinearGradient(colors: [.white, .clear],
                                                     startPoint: .top, endPoint: .bottom))
                        )
                )
                .foregroundStyle(.white)
                .shadow(color: AppColors.primary.opacity(0.10), radius: 12, x: 0, y: 4)
                .zIndex(2)
                .padding(.horizontal)
            }
        }
        .hideKeyboardOnTap()
        .navigationBarBackButtonHidden(true)
        .background(AppColors.background.ignoresSafeArea())
        .onAppear { draft = vm.meal }
        .gesture(
            DragGesture().onEnded { value in
                if value.translation.height > 100 {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.9)) { isPresented = false }
                }
            }
        )
    }

    
    // MARK: - Plus Capsule
    struct PlusCapsuleButton: View {
        var width: CGFloat? = 140     
        var height: CGFloat = 56
        var iconSize: CGFloat = 18
        var radius: CGFloat? = nil
        var action: () -> Void

        private var corner: CGFloat { radius ?? height / 2 }

        var body: some View {
            Button(action: action) {
                AppImages.ButtonIcons.Plus.darkPlus
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: iconSize, height: iconSize)
                    .foregroundStyle(AppColors.primary)
                    .frame(width: width, height: height)
            }
            .buttonStyle(.plain)
            .background(
                RoundedRectangle(cornerRadius: corner, style: .continuous).fill(.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .stroke(AppColors.primary.opacity(0.10), lineWidth: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .stroke(.white.opacity(0.9), lineWidth: 1)
                    .blendMode(.overlay)
                    .offset(y: -1)
                    .mask(
                        RoundedRectangle(cornerRadius: corner, style: .continuous)
                            .fill(LinearGradient(colors: [.white, .clear], startPoint: .top, endPoint: .bottom))
                    )
            )
            .shadow(color: .black.opacity(0.06), radius: 4, y: 0)
            .contentShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
        }
    }

    // MARK: - Subviews

//    private var grabber: some View {
//        Capsule()
//            .frame(width: 44, height: 5)
//            .foregroundStyle(Color.secondary.opacity(0.3))
//            .padding(.top, 8)
//    }

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

            IngredientList(ingredients: Binding(
                get: { vm.meal.ingredients },
                set: { newValue in
                    var m = vm.meal
                    m.ingredients = newValue
                    vm.meal = m
                }
            ))
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
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
            .foregroundStyle(AppColors.secondary.opacity(0.6))
            .keyboardType(.numberPad)
            Spacer()
            Text(unit).foregroundColor(AppColors.primary)
        }
        .padding(.vertical, 12).padding(.horizontal, 14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

#Preview {
    NavigationStack {
        MealEditSheet(vm: .preview, isPresented: .constant(true))
    }
}
