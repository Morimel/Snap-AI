//
//  MetricPill.swift
//  SnapAI
//
//  Created by Isa Melsov on 23/9/25.
//

import SwiftUI

struct MetricBadge {
    enum Kind {
        case system(String)      
        case text(String)
        case image(Image)
    }
    let kind: Kind
    let color: Color
}


private enum PillUI {
    static let height: CGFloat = 56
    static let radius: CGFloat = 22
    static let hpad: CGFloat = 18
    static let spacing: CGFloat = 12
}


struct MetricPill: View {
    let title: String
    let value: String
    var badge: MetricBadge? = nil
    var radius: CGFloat = 22
    var height: CGFloat = 56

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(AppColors.primary)

            HStack(spacing: 12) {
                if let badge {
                    BadgeView(badge: badge)
                }
                Text(value)
                    .font(.headline)
                    .foregroundStyle(AppColors.primary)
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, minHeight: height, alignment: .leading)
            .padding(.horizontal, 18)
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(AppColors.primary.opacity(0.10), lineWidth: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(.white.opacity(0.9), lineWidth: 1)
                    .blendMode(.overlay)
                    .offset(y: -1)
                    .mask(
                        RoundedRectangle(cornerRadius: radius, style: .continuous)
                            .fill(LinearGradient(colors: [.white, .clear],
                                                 startPoint: .top, endPoint: .bottom))
                    )
            )
            .shadow(color: AppColors.primary.opacity(0.15), radius: 6, x: 0, y: 3)
        }
    }
}

struct BadgeView: View {
    let badge: MetricBadge
    var body: some View {
        Circle()
            .fill(badge.color)
            .frame(width: 32, height: 32)
            .overlay(content)
    }

    @ViewBuilder
    private var content: some View {
        switch badge.kind {
        case .system(let name):
            Image(systemName: name)
                .font(.caption2.weight(.black))
                .foregroundStyle(.white)
        case .text(let str):
            Text(str)
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
        case .image(let img):
            img
                .resizable()
                .scaledToFit()
                .padding(6)
                .foregroundStyle(.white)
        }
    }
}


struct StepperPill<FieldID: Hashable>: View {
    let title: String
    @Binding var value: Int
    var min: Int = 1
    var max: Int? = nil

    let field: FieldID
    let focused: FocusState<FieldID?>.Binding

    private var intFormatter: NumberFormatter {
        let f = NumberFormatter()
        f.numberStyle = .none
        f.allowsFloats = false
        f.minimum = NSNumber(value: min)
        if let max { f.maximum = NSNumber(value: max) }
        return f
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(AppColors.primary)

            HStack(spacing: PillUI.spacing) {
                RoundIconButton(systemName: "minus") {
                    value = Swift.max(min, value - 1)
                }

                TextField("", value: $value, formatter: intFormatter)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .font(.headline)
                    .foregroundStyle(AppColors.primary)
                    .frame(minWidth: 40)
                    .focused(focused, equals: field)
                    .onChange(of: value) { new in
                        if new < min { value = min }
                        if let max, new > max { value = max }
                    }

                RoundIconButton(systemName: "plus") {
                    if let max { value = Swift.min(max, value + 1) } else { value += 1 }
                }

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, minHeight: PillUI.height, alignment: .leading)
            .padding(.horizontal, PillUI.hpad)
            .background(RoundedRectangle(cornerRadius: PillUI.radius, style: .continuous).fill(.white))
            .overlay(RoundedRectangle(cornerRadius: PillUI.radius, style: .continuous)
                .stroke(AppColors.primary.opacity(0.10), lineWidth: 1))
            .overlay(
                RoundedRectangle(cornerRadius: PillUI.radius, style: .continuous)
                    .stroke(.white.opacity(0.9), lineWidth: 1)
                    .blendMode(.overlay)
                    .offset(y: -1)
                    .mask(RoundedRectangle(cornerRadius: PillUI.radius)
                        .fill(LinearGradient(colors: [.white, .clear], startPoint: .top, endPoint: .bottom)))
            )
            .shadow(color: AppColors.primary.opacity(0.15), radius: 6, x: 0, y: 3)
        }
    }
}


struct ChangeTarget: View {
    @Environment(\.dismiss) private var dismiss

    @State private var showEditor = false
    @State private var calories = 1958
    @State private var proteins = 50
    @State private var carbohydrates = 150
    @State private var fats = 32

    @FocusState private var focusedField: Field?

    enum Field: Hashable {
        case calories, proteins, carbs, fats
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
                withAnimation(.spring(response: 0.32, dampingFraction: 0.9)) { showEditor = true }
            } label: {
                Text("Edit")
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 56)
            }
            .buttonStyle(.plain)
            .background(RoundedRectangle(cornerRadius: 28).fill(AppColors.secondary))
            .overlay(RoundedRectangle(cornerRadius: 28).stroke(AppColors.primary.opacity(0.10), lineWidth: 1))
            .overlay(
                RoundedRectangle(cornerRadius: 28)
                    .stroke(.white.opacity(0.9), lineWidth: 1)
                    .blendMode(.overlay)
                    .offset(y: -1)
                    .mask(RoundedRectangle(cornerRadius: 28)
                        .fill(LinearGradient(colors: [.white, .clear], startPoint: .top, endPoint: .bottom)))
            )
            .foregroundStyle(.white)
            .shadow(color: AppColors.primary.opacity(0.10), radius: 12, x: 0, y: 4)
            .zIndex(2)

            Spacer()
        }
        .padding(.horizontal)
        .background(AppColors.background)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: { dismiss() }) {
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
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { focusedField = nil }
            }
        }
    }
}


private struct RoundIconButton: View {
    let systemName: String
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white)
        }
        .frame(width: 32, height: 32)
        .background(AppColors.primary, in: Circle())
        .overlay(Circle().stroke(AppColors.primary.opacity(0.10), lineWidth: 1))
        .contentShape(Circle())
    }
}



