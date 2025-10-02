//
//  ChangeTargetView.swift
//  SnapAI
//
//  Created by Isa Melsov on 24/9/25.
//

import SwiftUI

struct ChangeTargetView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var calories: Int
    @State private var proteins: Int
    @State private var carbohydrates: Int
    @State private var fats: Int
    
    @State private var saving = false
    @State private var showSnack = false
    @State private var snackText = "Saved"
    @State private var error: String?
    
    let onSave: (Int, Int, Int, Int) async -> Void
    
    @FocusState private var focusedField: Field?
    
    enum Field: Hashable { case calories, proteins, carbs, fats }
    
    init(
        initialCalories: Int,
        initialProteins: Int,
        initialCarbs: Int,
        initialFats: Int,
        onSave: @escaping (Int, Int, Int, Int) async -> Void
    ) {
        _calories      = State(initialValue: initialCalories)
        _proteins      = State(initialValue: initialProteins)
        _carbohydrates = State(initialValue: initialCarbs)
        _fats          = State(initialValue: initialFats)
        self.onSave    = onSave
    }
    
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
            
            
            Button {
                Task { await saveAndClose() }
            } label: {
                Text(saving ? "Saving..." : "Save")
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 56)
                    .foregroundColor(.white)
                    .background(AppColors.secondary)
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            }
            .disabled(saving)
            .buttonStyle(.plain)
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(AppColors.primary.opacity(0.10), lineWidth: 1)
            )
            .shadow(color: AppColors.primary.opacity(0.10), radius: 12, x: 0, y: 4)
            .zIndex(2)

            Spacer()
        }
        .overlay(alignment: .bottom) {
            if showSnack {
                SnackBarView(text: snackText)
            }
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
    
    private func saveAndClose() async {
        await MainActor.run {
            saving = true
            error = nil
            focusedField = nil
        }

        // тут — твои данные уже в @State (calories/proteins/...), просто пробрасываем
        await onSave(calories, proteins, carbohydrates, fats)

        await MainActor.run {
            saving = false
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            snackText = "Saved"
            withAnimation { showSnack = true }
        }

        try? await Task.sleep(nanoseconds: 1_400_000_000)

        await MainActor.run {
            withAnimation { showSnack = false }
            dismiss()
        }
    }

}


#Preview {
    NavigationStack {
        ChangeTargetView(
            initialCalories: 1958,
            initialProteins: 50,
            initialCarbs: 150,
            initialFats: 32
        ) { _,_,_,_ in }
    }
}
