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
    
    @State private var saving = false
    @State private var loading = false
    @State private var error: String?
    
    @State private var didInitialPreload = false
    
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
    
    @State private var showSnack = false
    @State private var snackText = "Saved"
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let error { Text(error).foregroundColor(.red) }
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
        .overlay {
            if loading || saving { ProgressView().controlSize(.large) }
        }
        .navigationBarBackButtonHidden(true)
        
        .safeAreaInset(edge: .bottom) {
            if showSnack {
                SnackBarView(text: snackText)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.spring(response: 0.35, dampingFraction: 0.9), value: showSnack)
            } else { EmptyView() }
        }

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
                Text("Personal data")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(AppColors.primary)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") { Task { await save() } }
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(AppColors.primary)
            }
        }
        .background(AppColors.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .task {
            guard !didInitialPreload else { return }
            didInitialPreload = true
            await preload()
        }   // ⬅️ грузим с бэка при входе
        .onReceive(NotificationCenter.default.publisher(for: .profileDidChange)) { _ in
            Task { await preload() }
        }
    }
    
    // MARK: - Load from backend
    private func preload() async {
        await MainActor.run { loading = true; error = nil }
        CurrentUser.ensureIdFromJWTIfNeeded()
        guard let id = UserStore.id() else {
            await MainActor.run { error = "User ID not found"; loading = false }
            return
        }
        do {
            let p = try await AuthAPI.shared.getProfile(id: id)
            await MainActor.run {
                UserStore.saveProfileId(p.id)        // 👈 СОХРАНИЛИ profile.id
                vm.data.fill(from: p)
                
                // Обновляем отображаемые строки
                gender = (p.gender ?? "—").capitalized
                age    = ageString(from: p.date_of_birth)
                height = displayHeight(cm: p.height_cm, units: p.units)
                weight = displayWeight(kg: p.weight_kg, units: p.units)
                loading = false
            }
        } catch {
            await MainActor.run { self.error = error.localizedDescription; loading = false }
        }
    }
    
    
    
    
    // MARK: - Save to backend
    private func save() async {
        await MainActor.run { saving = true; error = nil }
        do {
            try await AuthAPI.shared.updateProfile(from: vm.data)

            // обновим «красивые» строки после сохранения
            let units = (vm.data.unit == .imperial) ? "imperial" : "metric"
            height = {
                let cmVal = units == "imperial" ? Int(round((vm.data.height ?? 0) * 2.54)) : Int(round(vm.data.height ?? 0))
                return displayHeight(cm: cmVal, units: units)
            }()
            weight = {
                let kgVal = units == "imperial" ? Int(round((vm.data.weight ?? 0) * 0.45359237)) : Int(round(vm.data.weight ?? 0))
                return displayWeight(kg: kgVal, units: units)
            }()
            if let g = vm.data.gender {
                gender = (g == .male ? "Male" : g == .female ? "Female" : "Other")
            }
            if let d = vm.data.birthDate {
                let years = Calendar.current.dateComponents([.year], from: d, to: Date()).year ?? 0
                age = "\(max(0, years)) years old"
            }

            // ⬇️ snackbar + haptic
            await MainActor.run {
                saving = false
                UINotificationFeedbackGenerator().notificationOccurred(.success) // haptic
                snackText = "Saved"
                withAnimation { showSnack = true }
            }
            Task {
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                await MainActor.run { withAnimation { showSnack = false } }
            }
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
                saving = false
            }
        }
    }

    
    fileprivate func ageString(from dob: String?) -> String {
        guard let dob else { return "—" }
        let df = DateFormatter(); df.dateFormat = "yyyy-MM-dd"; df.timeZone = .init(secondsFromGMT: 0)
        let iso = ISO8601DateFormatter()
        let date = df.date(from: dob) ?? iso.date(from: dob)
        guard let date else { return "—" }
        let years = Calendar.current.dateComponents([.year], from: date, to: Date()).year ?? 0
        return "\(years) years old"
    }
    
    fileprivate func displayWeight(kg: Int?, units: String?) -> String {
        guard let kg else { return "—" }
        let imp = (units ?? "metric").lowercased() == "imperial"
        return imp ? "\(Int(round(Double(kg) * 2.20462262))) lbs" : "\(kg) kg"
    }
    
    fileprivate func displayHeight(cm: Int?, units: String?) -> String {
        guard let cm else { return "—" }
        let imp = (units ?? "metric").lowercased() == "imperial"
        if !imp { return "\(cm) cm" }
        let inchesTotal = Int(round(Double(cm) / 2.54))
        let ft = inchesTotal / 12, inch = inchesTotal % 12
        return "\(ft)'\(inch)\""
    }
    
}

struct SnackBarView: View {
    let text: String
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
            Text(text).font(.callout).fontWeight(.semibold)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, minHeight: 48)
        .foregroundColor(.white)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.black.opacity(0.85))
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .shadow(radius: 8, y: 4)
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



