//
//  Untitled.swift
//  SnapAI
//
//  Created by Isa Melsov on 23/9/25.
//

import SwiftUI

//MARK: - MainScreen
struct MainScreen: View {
    
    @ObservedObject var vm: OnboardingViewModel
    
    @State private var selected = Date()
    @State private var isLoadingMeals = false
    
    @State private var selectedMeal: Meal?
    @State private var selectedImage: UIImage?
    
    var onNext: (() -> Void)? = nil
    private var p: PersonalPlan? { vm.personalPlan }
    
    
    @State private var showCamera = false
    private struct CropSession: Identifiable { let id = UUID(); let image: UIImage }
    @State private var cropSession: CropSession?
    @State private var showMealDetail = false
    @State private var pendingCropped: UIImage?
    
    @StateObject private var mealVM = MealViewModel()
    
    private struct EatenMeal: Identifiable, Equatable {
        let id: String
        var meal: Meal
        var image: UIImage?
    }
    
    @State private var eaten: [EatenMeal] = []
        
    private var totals: (kcal: Int, p: Int, f: Int, c: Int) {
        eaten.reduce(into: (0,0,0,0)) { acc, item in
            let m = item.meal
            let servings = max(m.servings, 1)
            acc.kcal += m.calories * servings
            acc.p    += m.proteins * servings
            acc.f    += m.fats * servings
            acc.c    += m.carbs * servings
        }
    }
    
    var body: some View {
        ScrollView {
            VStack {
                WeekStrip(selected: $selected)
                
                if let p = vm.personalPlan {
                    StatisticsCard(
                        needKcal: p.dailyCalories,
                        spentKcal: totals.kcal,                 // 👈 суммарные калории
                        protein: (totals.p, p.protein),         // 👈 protein.current
                        fat:     (totals.f, p.fat),             // 👈 fat.current
                        carb:    (totals.c, p.carbs)            // 👈 carb.current
                    )
                } else {
                    StatisticsCard(
                        needKcal: 0,
                        spentKcal: totals.kcal,
                        protein: (totals.p, 0),
                        fat:     (totals.f, 0),
                        carb:    (totals.c, 0)
                    )
                    .redacted(reason: .placeholder)
                }
                
                HStack {
                    Text("History")
                        .foregroundStyle(AppColors.primary)
                        .font(.system(size: 16, weight: .semibold, design: .default))
                        .padding(.horizontal)
                    
                    Spacer()
                }
                
                LazyVGrid(columns: [.init(.flexible())], spacing: 14) {
                    if eaten.isEmpty {
                        EpmtyCardView()
                    } else {
                        ForEach(eaten) { item in
                            Button {
                                    openDetail(for: item)
                                } label: {
                                    FoodCardView(meal: item.meal, image: item.image)
                                }
                                .buttonStyle(.plain)
                        }
                    }
                }
                }
            }
        .scrollIndicators(.hidden)
            .safeAreaInset(edge: .bottom) {
                StickyPlusButton() {
                    showCamera = true
                }
            }
            .onAppear { refreshMeals() }
            .onChange(of: selected) { _ in refreshMeals() }
            .background(AppColors.background.ignoresSafeArea())
            .toolbarBackground(.hidden, for: .navigationBar)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text("Snap AI")
                        .foregroundStyle(AppColors.primary)
                        .font(.system(size: 24, weight: .semibold))
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        SettingsView(vm: vm)
                    } label: {
                        AppImages.ButtonIcons.gear
                            .resizable()
                            .scaledToFill()
                            .frame(width: 20, height: 20)
                    }
                }
            }
            .fullScreenCover(isPresented: $showCamera) {
                NavigationStack {
                    CameraScreen { cropped in
                        pendingCropped = cropped
                        mealVM.resetForNewAnalyze()
                        showCamera = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                            showMealDetail = true
                        }
                    }
                }
            }
            .navigationDestination(isPresented: $showMealDetail) {
                if let img = pendingCropped {
                    MealDetailScreen(
                        image: img,
                        vm: mealVM,
                        onClose: {
                            showMealDetail = false
                            pendingCropped = nil
                        }
                    )
                } else {
                    // сюда мы теперь вообще не попадём
                    ProgressView()
                }
            }


            .task { await vm.ensurePlanLoaded() }
        }
    
    // MARK: - Open detail from card
    @MainActor
        private func openDetail(for item: EatenMeal) {
            // 1) зачищаем состояние "анализа" и передаём выбранный meal
            mealVM.resetForNewAnalyze()
            mealVM.meal = item.meal

            // 2) картинка: если есть локальная — берём её; иначе попробуем скачать по imagePath
            if let img = item.image {
                pendingCropped = img
                showMealDetail = true
                return
            }

            Task {
                    var ui: UIImage? = nil
                    if let url = mediaURL(from: item.meal.imagePath),
                       let (data, _) = try? await URLSession.shared.data(from: url) {
                        ui = UIImage(data: data)
                    }

                    // 👇 ВСЕ обновления стейта — на MainActor и только затем пушим экран
                    await MainActor.run {
                        self.pendingCropped = ui ?? .previewPlaceholder
                        self.showMealDetail = true
                    }
                }
        }
    
    // такой же помощник, как в FoodCardView (можно вынести в утиль)
        private func mediaURL(from raw: String?) -> URL? {
            guard let s0 = raw?.trimmingCharacters(in: .whitespacesAndNewlines), !s0.isEmpty else { return nil }
            var s = s0
            if s.hasPrefix("/media/") || s.hasPrefix("media/") {
                s = "https://snap-ai-app.com" + (s.hasPrefix("/") ? s : "/\(s)")
            }
            guard var comps = URLComponents(string: s) else { return nil }
            if comps.scheme == nil { comps.scheme = "https"; comps.host = comps.host ?? "snap-ai-app.com" }
            else if comps.scheme?.lowercased() == "http" { comps.scheme = "https" }
            return comps.url
        }
    
    // MARK: - Helpers
    private func upsertFromVM(using image: UIImage?) {
        let m = mealVM.meal
        guard !m.title.isEmpty || (m.id != nil) else { return }
        let key = m.id.map(String.init) ?? UUID().uuidString

        if let idx = eaten.firstIndex(where: { $0.id == key }) {
            eaten[idx].meal = m
            if image != nil { eaten[idx].image = image }
        } else {
            eaten.insert(.init(id: key, meal: m, image: image), at: 0)
        }
        if let mid = m.id { MealsLocalIndex.add(id: mid, for: selected) }   // ⬅️ сохраняем id для перезапуска

        print("Σ totals → kcal=\(totals.kcal), P=\(totals.p), F=\(totals.f), C=\(totals.c)")
    }
    
    private func refreshMeals() {
        Task {
            isLoadingMeals = true
            defer { isLoadingMeals = false }

            do {
                let list = try await AuthAPI.shared.listMeals(on: selected)
                if !list.isEmpty {
                    await MainActor.run {
                        self.eaten = list.map {
                            .init(id: ($0.id.map(String.init) ?? UUID().uuidString),
                                  meal: $0,
                                  image: nil)
                        }
                    }
                    print("✅ refreshMeals: loaded \(list.count) from server for \(selected)")
                    return
                } else {
                    print("ℹ️ refreshMeals: server returned empty list for \(selected)")
                }
            } catch {
                print("❌ refreshMeals: listMeals failed:", error.localizedDescription)
            }

            // fallback по локальному индексу (после переустановки он пустой — это ок)
            let ids = MealsLocalIndex.ids(for: selected)
            if !ids.isEmpty {
                var items: [EatenMeal] = []
                for id in ids {
                    do {
                        let meal = try await AuthAPI.shared.getMeal(id: id)
                        items.append(.init(id: String(id), meal: meal, image: nil))
                    } catch {
                        print("⚠️ getMeal(\(id)) failed: \(error.localizedDescription)")
                    }
                }
                await MainActor.run { self.eaten = items }
                print("✅ refreshMeals: loaded \(items.count) by local ids")
            } else {
                print("ℹ️ refreshMeals: no server data and no local ids — keeping current UI")
            }
        }
    }
}
    
    #Preview {
        NavigationStack {
            MainScreen_Preview()
        }
    }
    
    private struct MainScreen_Preview: View {
        @StateObject private var vm = OnboardingViewModel(
            repository: LocalRepository(),
            onFinished: {}
        )
        
        var body: some View {
            NavigationStack {
                MainScreen(vm: vm)
            }
        }
    }
    
    
    extension OnboardingViewModel {
        func ensurePlanLoaded() async {
            if personalPlan != nil { return }
            do {
                let g = try await AuthAPI.shared.getCurrentPlan()
                await MainActor.run {
                    self.personalPlan = PersonalPlan(
                        weightUnit: "kg",
                        maintainWeight: 0,
                        dailyCalories: g.dailyCalories,
                        protein: g.proteinG,
                        fat: g.fatG,
                        carbs: g.carbsG,
                        meals: [],
                        workouts: []
                    )
                }
            } catch {
                print("get_plan failed:", error.localizedDescription)
            }
        }
    }
