//
//  SettingScreen.swift
//  SnapAI
//
//  Created by Isa Melsov on 22/9/25.
//

import SwiftUI

// MARK: - Reusable pieces
struct SectionHeader: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.title2.weight(.semibold))
            .foregroundColor(AppColors.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
    }
}

struct SectionCard<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        VStack(spacing: 0) { content }
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(.black.opacity(0.06), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
            .padding(.horizontal, 16)
    }
}

struct KeyValueRow: View {
    let key: String
    let value: String
    var body: some View {
        HStack {
            Text(key)
                .font(.headline.weight(.semibold))
                .foregroundColor(AppColors.primary)
            Spacer(minLength: 16)
            Text(value)
                .font(.callout)
                .foregroundColor(AppColors.primary)
        }
        .frame(height: 54)
        .contentShape(Rectangle())
        .padding(.horizontal, 16)
    }
}

struct ChevronRow: View {
    let title: String
    let onTap: () -> Void
    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(title)
                    .font(.headline.weight(.semibold))
                    .foregroundColor(AppColors.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.primary)
            }
            .frame(height: 54)
            .padding(.horizontal, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Settings Screen
struct SettingsView: View {
    // Данные для примера; подмени своими
    @State private var gender = "Male"
    @State private var age = "27 years old"
    @State private var height = "5'9\""
    @State private var weight = "150 lbs"
    @State private var goal = "135 lbs"

    var body: some View {
        AppNavigationContainer {
            ScrollView {
                VStack(spacing: 24) {
                    // Карточка с ключ-значение
                    SectionCard {
                        KeyValueRow(key: "Gender", value: gender)
                        KeyValueRow(key: "Age", value: age)
                        KeyValueRow(key: "Height", value: height)
                        KeyValueRow(key: "Weight", value: weight)
                        KeyValueRow(key: "Goal", value: goal)
                    }

                    // Персонализация
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(title: "Personalization")
                        SectionCard {
                            NavigationLink {
                                PersonalDataView(
                                    gender: $gender,
                                    age: $age,
                                    height: $height,
                                    weight: $weight
                                )
                                .navigationTitle("Personal data")
                                .navigationBarTitleDisplayMode(.inline)
                            } label: {
                                HStack {
                                    Text("Personal information")
                                        .font(.headline.weight(.semibold))
                                        .foregroundStyle(AppColors.primary)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(AppColors.primary)
                                }
                                .frame(height: 54)
                                .padding(.horizontal, 16)
                            }
                            ChevronRow(title: "Change goals") {
                                // TODO: открыть экран смены целей
                            }
                        }
                    }

                    // Support
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(title: "Support service")
                        SectionCard {
                            ChevronRow(title: "Support service") {
                                // TODO: открыть чат/почту
                            }
                            ChevronRow(title: "Terms") { }
                            ChevronRow(title: "Privacy") { }
                        }
                    }

                    Text("App version: 1.0.0")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 4)
                }
                .padding(.vertical, 16)
            }
            .background(AppColors.background.ignoresSafeArea())
            .toolbarBackground(.hidden, for: .navigationBar)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                
                ToolbarItemGroup(placement: .topBarLeading) {
                    AppImages.ButtonIcons.arrowRight
                        .resizable()
                        .scaledToFill()
                        .frame(width: 12, height: 12)
                        .rotationEffect(.degrees(180))
                        .padding()
                    
                    Text("Settings")
                        .foregroundStyle(AppColors.primary)
                        .font(.system(size: 24, weight: .semibold))
                        
                }
            }
        }
    }
}

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


// MARK: - Gender

struct GenderPickerSheet: View {
    @Binding var value: String
    @Environment(\.dismiss) private var dismiss

    private let options = ["Male", "Female", "Other"]

    var body: some View {
        NavigationStack {
            List {
                ForEach(options, id: \.self) { option in
                    Button {
                        value = option
                        dismiss()
                    } label: {
                        HStack {
                            Text(option)
                            Spacer()
                            if option == value {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                    .foregroundColor(.primary)
                }
            }
            .navigationTitle("Gender")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } } }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - Age

struct AgePickerSheet: View {
    @Binding var value: String
    @Environment(\.dismiss) private var dismiss

    @State private var ageInt: Int = 27
    private let range = Array(10...100)

    var body: some View {
        NavigationStack {
            VStack {
                Picker("Age", selection: $ageInt) {
                    ForEach(range, id: \.self) { Text("\($0)") }
                }
                .pickerStyle(.wheel)
                .frame(maxHeight: 220)

                Text("\(ageInt) years old")
                    .font(.headline)
                    .padding(.top, 8)

                Spacer()
            }
            .padding()
            .navigationTitle("Age")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        value = "\(ageInt) years old"
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            if let n = Int(value.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()) {
                ageInt = n
            }
        }
        .presentationDetents([.height(300)])
    }
}

// MARK: - Height (ft/in)

struct HeightPickerSheet: View {
    @Binding var value: String
    @Environment(\.dismiss) private var dismiss

    @State private var feet: Int = 5
    @State private var inches: Int = 9

    private let feetRange = Array(3...7)
    private let inchRange = Array(0...11)

    var body: some View {
        NavigationStack {
            VStack(spacing: 8) {
                HStack {
                    Picker("Feet", selection: $feet) {
                        ForEach(feetRange, id: \.self) { Text("\($0) ft") }
                    }
                    Picker("Inches", selection: $inches) {
                        ForEach(inchRange, id: \.self) { Text("\($0) in") }
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 220)

                Text(formatted(feet: feet, inches: inches))
                    .font(.headline)
                Spacer()
            }
            .padding()
            .navigationTitle("Height")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        value = formatted(feet: feet, inches: inches)
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            let parsed = parse(value)
            feet = parsed.feet
            inches = parsed.inches
        }
        .presentationDetents([.height(320)])
    }

    private func formatted(feet: Int, inches: Int) -> String {
        "\(feet)\'\(inches)\""
    }

    private func parse(_ s: String) -> (feet: Int, inches: Int) {
        // ожидаем формат вида 5'9"
        let digits = s.split(whereSeparator: { !"0123456789".contains($0) }).compactMap { Int($0) }
        let f = digits.first ?? 5
        let i = digits.dropFirst().first ?? 9
        return (feet: min(max(f, feetRange.first!), feetRange.last!),
                inches: min(max(i, inchRange.first!), inchRange.last!))
    }
}

// MARK: - Weight (lbs)

struct WeightPickerSheet: View {
    @Binding var value: String
    @Environment(\.dismiss) private var dismiss

    @State private var lbs: Int = 175
    private let range = Array(80...400)

    var body: some View {
        NavigationStack {
            VStack {
                Picker("Weight", selection: $lbs) {
                    ForEach(range, id: \.self) { Text("\($0)") }
                }
                .pickerStyle(.wheel)
                .frame(height: 220)

                Text("\(lbs) lbs").font(.headline)
                Spacer()
            }
            .padding()
            .navigationTitle("Weight")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        value = "\(lbs) lbs"
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            if let n = Int(value.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()) {
                lbs = n
            }
        }
        .presentationDetents([.height(300)])
    }
}


// MARK: - Reusable row (как у тебя)

struct LabeledPillRow: View {
    let label: String
    let value: String
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.title3.weight(.semibold))
                .foregroundColor(AppColors.primary)
                .padding(.horizontal, 16)

            Button(action: action) {
                HStack {
                    Text(value)
                        .foregroundColor(AppColors.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(AppColors.secondary)
                }
                .padding(.horizontal, 14)
                .frame(height: 46)
                .background(
                    Capsule(style: .continuous)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.06), radius: 6, y: 1)
                )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 16)
            .padding(.bottom, 6)
        }
        .padding(.vertical, 2)
    }
}

//struct LabeledPillRow: View {
//    let label: String
//    let value: String
//    let action: () -> Void
//
//    var body: some View {
//        VStack(alignment: .leading, spacing: 8) {
//            Text(label)
//                .font(.title3.weight(.semibold))
//                .foregroundColor(AppColors.primary)
//                .padding(.horizontal, 16)
//
//            Button(action: action) {
//                HStack {
//                    Text(value)
//                        .foregroundColor(AppColors.primary)
//                    Spacer()
//                    Image(systemName: "chevron.right")
//                        .foregroundColor(AppColors.secondary)
//                }
//                .padding(.horizontal, 14)
//                .frame(height: 46)
//                .background(
//                    Capsule(style: .continuous)
//                        .fill(Color(.systemBackground))
//                        .shadow(color: .black.opacity(0.06), radius: 6, y: 1)
//                )
//            }
//            .buttonStyle(.plain)
//            .padding(.horizontal, 16)
//            .padding(.bottom, 6)
//        }
//        .padding(.vertical, 2)
//    }
//}



// MARK: - Previews
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            SettingsView()
            PersonalDataView(
                gender: .constant("Male"),
                age: .constant("27 years old"),
                height: .constant("5'9\""),
                weight: .constant("175 lbs")
            )
            .navigationTitle("Personal data")
        }
    }
}

