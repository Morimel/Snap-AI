//
//  SettingsView.swift
//  SnapAI
//
//  Created by Isa Melsov on 23/9/25.
//

import SwiftUI
import GoogleSignIn

// MARK: - Settings Screen
struct SettingsView: View {
    @ObservedObject var vm: OnboardingViewModel
    
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    
    @State private var gender = "—"
    @State private var age = "—"
    @State private var height = "—"
    @State private var weight = "—"
    @State private var goal = "—"
    
    @State private var targetWeight = "—"
    
    @State private var planLoading = false
        @State private var planError: String?
    
    @State private var cal = 0
    @State private var prot = 0
    @State private var crb = 0
    @State private var fat = 0
    
    @State private var loading = false
    @State private var error: String?
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                
                if let error {
                    Text(error).foregroundColor(.red).padding(.horizontal)
                }
                // Карточка с ключ-значение
                SectionCard {
                    KeyValueRow(key: "Gender", value: gender)
                    KeyValueRow(key: "Age", value: age)
                    KeyValueRow(key: "Height", value: height)
                    KeyValueRow(key: "Weight", value: weight)
                    KeyValueRow(key: "Goal", value: targetWeight)
                }
                
                // Персонализация
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "Personalization")
                    SectionCard {
                        NavigationLink {
                            PersonalDataView(
                                vm: vm,
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
                        .overlay {
                            if loading { ProgressView().controlSize(.large) }
                        }
                        
                        NavigationLink {
                            GoalStep(vm: vm, mode: .picker)
                                .navigationTitle("Change goal")
                                .navigationBarTitleDisplayMode(.inline)
                        } label: {
                            HStack {
                                Text("Change goals")
                                    .font(.headline.weight(.semibold))
                                    .foregroundStyle(AppColors.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(AppColors.primary)
                            }
                            .frame(height: 54)
                            .padding(.horizontal, 16)
                        }
                        
                        NavigationLink {
                            let p = vm.personalPlan
                            ChangeTargetView(
                                initialCalories: p?.dailyCalories ?? cal,
                                initialProteins: p?.protein       ?? prot,
                                initialCarbs:    p?.carbs         ?? crb,
                                initialFats:     p?.fat           ?? fat
                            ) { cal, prot, carbs, fats in
                                await vm.saveManualPlan(
                                    calories: cal,
                                    proteins: prot,
                                    carbs: carbs,
                                    fats: fats
                                )
                                await loadPlan()
                            }
                        } label: {
                            row("Change targets")
                                .overlay(alignment: .trailing) {
                                    if planLoading { ProgressView().controlSize(.small).padding(.trailing, 16) }
                                }
                        }
                        
                    }
                }
                if let planError {
                                    Text(planError).foregroundColor(.red).font(.footnote)
                                }
                
                // Support
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "Support service")
                    SectionCard {
                        NavigationLink {
                            SupportFormView()
                                .navigationBarTitleDisplayMode(.inline)
                        } label: {
                            HStack {
                                Text("Support service")
                                    .font(.headline.weight(.semibold))
                                    .foregroundStyle(AppColors.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(AppColors.primary)
                            }
                            .frame(height: 54)
                            .padding(.horizontal, 16)
                        }
                        NavigationLink {
                            TermsOfServiceScreen(appName: "SnapAI",
                                                 company: "SnapAI",
                                                 email: "support@example.com",
                                                 effectiveDate: "01.10.2025")
                                .navigationBarTitleDisplayMode(.inline)
                        } label: {
                            HStack {
                                Text("Terms")
                                    .font(.headline.weight(.semibold))
                                    .foregroundStyle(AppColors.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(AppColors.primary)
                            }
                            .frame(height: 54)
                            .padding(.horizontal, 16)
                        }
                        NavigationLink {
                            PrivacyPolicyScreen(appName: "SnapAI",
                                                company: "SnapAI",
                                                email: "support@example.com",
                                                effectiveDate: "01.10.2025")
                                .navigationBarTitleDisplayMode(.inline)
                        } label: {
                            HStack {
                                Text("Privacy")
                                    .font(.headline.weight(.semibold))
                                    .foregroundStyle(AppColors.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(AppColors.primary)
                            }
                            .frame(height: 54)
                            .padding(.horizontal, 16)
                        }
                    }
                }
                
                Button {
                            goToStartView()            // ⬅️ просто отправляем на старт
                        } label: {
                            Text("Sign Out")
                                .font(.headline)
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity, minHeight: 48)
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)
                
                Text("App version: 1.0.0")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 4)
            }
            .padding(.vertical, 16)
        }
        .scrollIndicators(.hidden)
        .background(AppColors.background.ignoresSafeArea())
        .toolbarBackground(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            
            ToolbarItemGroup(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    AppImages.ButtonIcons.arrowRight
                        .resizable()
                        .scaledToFill()
                        .frame(width: 12, height: 12)
                        .rotationEffect(.degrees(180))
                        .padding()
                }
                
                Text("Settings")
                    .foregroundStyle(AppColors.primary)
                    .font(.system(size: 24, weight: .semibold))
                
            }
        }
        .task {
            await loadProfile()
            await loadPlan()
        }
        .onReceive(NotificationCenter.default.publisher(for: .profileDidChange)) { _ in
            Task {
                await loadProfile()
                await loadPlan()
            }
        }

    }
    
    
    private func goToStartView() {
        hasOnboarded = false        // RootContainer сам переключится на онбординг
        dismiss()                   // если Settings открыт модально — закрыть
    }



    
    // MARK: - Load plan
       private func loadPlan() async {
           await MainActor.run { planLoading = true; planError = nil }
           do {
               let g = try await AuthAPI.shared.getCurrentPlan()
               await MainActor.run {
                   cal = g.dailyCalories
                   prot = g.proteinG
                   crb = g.carbsG
                   fat = g.fatG
                   planLoading = false
               }
           } catch {
               await MainActor.run {
                   planError = error.localizedDescription
                   planLoading = false
               }
           }
       }
    
    @ViewBuilder
    private func row(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.headline.weight(.semibold))
                .foregroundStyle(AppColors.primary)
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(AppColors.primary)
        }
        .frame(height: 54)
        .padding(.horizontal, 16)
    }
    
    // MARK: - Load
    private func loadProfile() async {
        // если id не сохранён — попробуем вытащить из access JWT
        CurrentUser.ensureIdFromJWTIfNeeded()
        
        if UserStore.id() == nil, let access = TokenStore.load()?.access,
           let id = JWTTools.userId(from: access) {
            UserStore.save(id: id, email: JWTTools.email(from: access))
        }
        
        guard let id = UserStore.id() else {
            await MainActor.run {
                error = "User ID not found"
                loading = false
            }
            return
        }
        
        await MainActor.run { loading = true; error = nil }
        
        do {
            let p = try await AuthAPI.shared.getProfile(id: id)

            // ⚠️ Синхронизируем VM с профилем (ключевой момент)
            await MainActor.run {
                // units
                let unitsStr = (p.units ?? "metric").lowercased()
                vm.data.unit = (unitsStr == "imperial") ? .imperial : .metric

                // gender
                if let g = p.gender?.lowercased() {
                    vm.data.gender = Gender(rawValue: g) // убедись, что rawValue совпадает ("male"/"female")
                }

                // dob
                if let dob = p.date_of_birth {
                    let df = DateFormatter(); df.timeZone = .init(secondsFromGMT: 0); df.dateFormat = "yyyy-MM-dd"
                    vm.data.birthDate = df.date(from: dob)
                }

                // рост / вес / цель
                if let h = p.height_cm { vm.data.height = unitsStr == "imperial" ? Double(h) / 2.54 : Double(h) }
                if let w = p.weight_kg { vm.data.weight = unitsStr == "imperial" ? Double(w) * 2.20462262 : Double(w) }
                if let d = p.desired_weight_kg {
                    vm.data.desiredWeight = unitsStr == "imperial" ? Double(d) * 2.20462262 : Double(d)
                } else {
                    vm.data.desiredWeight = nil
                }

                // активность/goal (следи за rawValue)
                if let act = p.activity?.lowercased() { vm.data.lifestyle = Lifestyle(rawValue: act) }
                if let goalStr = p.goal, let g = Goal(rawValue: goalStr) {
                                vm.data.goal = g
                            }
            }

            await MainActor.run {
                
                vm.data.fill(from: p)   // Внутри fill(from:) уже есть self.goal = Goal(rawValue: g) — оставь,
                                            // но лучше замени на Goal(api: g) для гибкости:
                    // if let g = p.goal?.lowercased() { self.goal = Goal(api: g) ?? self.goal }
                applyProfile(p)      // как и было — заполнение строк для UI
                loading = false
            }
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
                self.loading = false
            }
        }
    }
    
    
    
    private func applyProfile(_ p: Profile) {
        // gender/age
        gender = (p.gender ?? "-").capitalized
        age    = ageString(from: p.date_of_birth)

        // units
        let units = (p.units ?? "metric").lowercased()

        // height
        if let cm = p.height_cm {
            height = (units == "imperial") ? feetInchesString(cm: cm) : "\(Int(round(Double(cm)))) cm"
        } else { height = "—" }

        // current weight (строка)
        let currentWeightStr: String = {
            guard let kg = p.weight_kg else { return "—" }
            let val = (units == "imperial") ? Int(round(Double(kg) * 2.20462262)) : Int(round(Double(kg)))
            return "\(val) " + ((units == "imperial") ? "lbs" : "kg")
        }()

        // target weight (строка). Если maintain (desired_weight_kg == null) — показываем текущий вес
        let targetWeightStr: String = {
            if let tkg = p.desired_weight_kg {
                let val = (units == "imperial") ? Int(round(Double(tkg) * 2.20462262)) : Int(round(Double(tkg)))
                return "\(val) " + ((units == "imperial") ? "lbs" : "kg")
            } else {
                return currentWeightStr
            }
        }()

        // goal (только текст цели)
        if let g = p.goal?.lowercased(), let goalEnum = Goal(api: g) {
            goal = goalEnum.displayName
        } else {
            goal = "—"
        }

        // присваиваем строки
        weight       = currentWeightStr
        targetWeight = targetWeightStr
    }

    
    private func ageString(from dob: String?) -> String {
        guard let dob else { return "—" }
        let df1 = DateFormatter(); df1.dateFormat = "yyyy-MM-dd"; df1.timeZone = .init(secondsFromGMT: 0)
        let iso = ISO8601DateFormatter()
        let date = df1.date(from: dob) ?? iso.date(from: dob)
        guard let date else { return "—" }
        let years = Calendar.current.dateComponents([.year], from: date, to: Date()).year ?? 0
        return "\(years) years old"
    }
    
    private func feetInchesString(cm: Int) -> String {
        let inchesTotal = Double(cm) / 2.54
        let ft = Int(inchesTotal / 12.0)
        let inch = Int(round(inchesTotal)) % 12
        return "\(ft)'\(inch)\""
    }
}

#Preview {
    SettingsView_Preview()
}

private struct SettingsView_Preview: View {
    @StateObject private var vm = OnboardingViewModel(
        repository: LocalRepository(),
        onFinished: {}
    )
    
    var body: some View {
        NavigationStack {
            SettingsView(vm: vm)
        }
    }
}

