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
    @Environment(\.scenePhase) private var scenePhase
    @State private var showAddIngredient = false
    
    @State private var saving = false
    @State private var showSnack = false
    @State private var snackText = "Saved"
    @State private var localError: String?

    @State private var draft = Meal()

    var body: some View {
        VStack(spacing: 16) {
            grabber

            Text("Edit mode")
                .foregroundStyle(AppColors.primary)
                .font(.title)
                .padding(.top, 8)

            ScrollView {
                form
                
                PlusCapsuleButton(width: 140, height: 56, iconSize: 20) {
                    showAddIngredient = true
                }
                .padding(.bottom, 16)
                
                
                Button {
                    Task { await saveAndClose() }
                } label: {
                    Text(saving ? "Saving..." : "Save")
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 56)
                        .foregroundColor(.white)
                        .contentTransition(.opacity)
                }
                .disabled(saving)
                .buttonStyle(.plain)
                .background(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(AppColors.secondary)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(AppColors.primary.opacity(0.10), lineWidth: 1)
                )
                .overlay(
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
            .overlay {
                if saving {
                    ProgressView()
                        .padding(14)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                }
            }

            .scrollIndicators(.hidden)
        }
        .overlay(alignment: .bottom) {
            if showSnack {
                SnackBarView(text: snackText)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.bottom, 8)
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
        .onChange(of: scenePhase) { phase in
                    // и .inactive, и .background — чтобы сработало при свайпе домой/мультизадачности
                    if phase == .inactive || phase == .background {
                        // 1) закрыть сам экран редактирования
                        isPresented = false
                        // 2) попросить родителя уйти на main
                        NotificationCenter.default.post(name: .dismissToMainFromEdit, object: nil)
                    }
                }
        .sheet(isPresented: $showAddIngredient) {
                    AddIngredientSheet { newIng in
                        draft.ingredients.append(newIng)   // 👈 добавляем в черновик
                    }
                }
        
        
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

    private var grabber: some View {
        Capsule()
            .frame(width: 44, height: 5)
            .foregroundStyle(AppColors.secondary.opacity(0.3))
            .padding(.top, 8)
    }

    private var form: some View {
        VStack(alignment: .leading, spacing: 16) {
            TextField("Meal name", text: $draft.title)
                .foregroundStyle(AppColors.primary)
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
                .foregroundStyle(AppColors.primary)
                .font(.title3.weight(.semibold))

            IngredientList(ingredients: $draft.ingredients, showAddButton: false)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
    
    private func saveAndClose() async {
        await MainActor.run {
            saving = true
            localError = nil
            // если надо — спрятать клаву:
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }

        // скидываем старую ошибку VM и сохраняем черновик
        await MainActor.run { vm.error = nil }

        // PATCH + RECOMPUTE
        await vm.saveAndRecompute(from: draft)

        // проверяем исход
        let err = await MainActor.run { vm.error }
        if let err, !err.isEmpty {
            await MainActor.run {
                saving = false
                localError = err
                UINotificationFeedbackGenerator().notificationOccurred(.error)
            }
            return
        }

        await MainActor.run {
            saving = false
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            snackText = "Saved"
            withAnimation { showSnack = true }
        }

        // показываем снек и закрываем
        try? await Task.sleep(nanoseconds: 1_400_000_000)
        await MainActor.run {
            withAnimation { showSnack = false }
            withAnimation(.spring(response: 0.32, dampingFraction: 0.9)) {
                isPresented = false
            }
        }
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


struct AddIngredientSheet: View {
    @State private var name = ""
    @State private var kcalText = ""
    let onDone: (Ingredient) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            Capsule().fill(.secondary.opacity(0.3))
                .frame(width: 44, height: 5).padding(.top, 8)

            Text("Add ingredient")
                .font(.title3.weight(.semibold))
                .foregroundStyle(AppColors.primary)

            VStack(spacing: 12) {
                TextField("Name", text: $name)
                    .padding().background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                HStack {
                    TextField("0", text: $kcalText)
                        .keyboardType(.numberPad)
                        .onChange(of: kcalText) { v in
                            kcalText = v.filter(\.isNumber)
                        }
                        .padding(.vertical, 12)
                    Spacer()
                    Text("kcal").foregroundStyle(AppColors.primary)
                }
                .padding(.horizontal, 14)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }

            Button("Done") {
                let kcal = Int(kcalText) ?? 0
                onDone(.init(name: name.trimmingCharacters(in: .whitespacesAndNewlines), kcal: kcal))
                dismiss()
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, minHeight: 56)
            .background(RoundedRectangle(cornerRadius: 28).fill(AppColors.secondary))
            .foregroundStyle(.white)
            .padding(.top, 8)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
        .background(AppColors.background.ignoresSafeArea())
        .presentationDetents([.fraction(0.32)])      // 👈 не на весь экран
        .presentationDragIndicator(.visible)
    }
}
