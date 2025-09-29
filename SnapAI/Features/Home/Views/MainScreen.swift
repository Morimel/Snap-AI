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
    
    @State private var selected = Date() // сегодня
    
    var onNext: (() -> Void)? = nil
    private var p: PersonalPlan? { vm.personalPlan }   // без force unwrap

    
    @State private var showCamera = false
    private struct CropSession: Identifiable { let id = UUID(); let image: UIImage }
    @State private var cropSession: CropSession?
    @State private var showMealDetail = false           // ← пуш детального экрана
    @State private var pendingCropped: UIImage?         // обрезанное фото
    
    var body: some View {
        ScrollView {
            VStack {
                // пример: неделя, где попадаем на «29 Aug → 4 Sep»
//                let ref = Calendar.current.date(from: DateComponents(year: 2025, month: 9, day: 29))!
//                WeekStrip(selected: $selected, reference: ref)
                WeekStrip(selected: $selected)
                
                if let p {
                                    StatisticsCard(
                                        needKcal: p.dailyCalories,
                                        spentKcal: 0,
                                        protein: (0, p.protein),
                                        fat:     (0, p.fat),
                                        carb:    (0, p.carbs)
                                    )
                                } else {
                                    // плейсхолдер, пока грузится
                                    StatisticsCard(
                                        needKcal: 0, spentKcal: 0,
                                        protein: (0, 0), fat: (0, 0), carb: (0, 0)
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
                EpmtyCardView()
            }
        }
        .safeAreaInset(edge: .bottom) {
            StickyPlusButton() {
                showCamera = true
            }
        }
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
                            // ⬇️ Навигация на SettingsView
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
        // Камера
        .fullScreenCover(isPresented: $showCamera) {
            NavigationStack {                           // 👈 добавили
                CameraScreen { cropped in           // ← уже обрезанное фото
                    pendingCropped = cropped
                    showCamera = false              // закрываем модалку камеры
                    // после закрытия — пушим детали
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                        showMealDetail = true
                    }
                }
            }
        }
        // 3) Пуш в MealDetailScreen
        // пушим после закрытия модалки
        .navigationDestination(isPresented: $showMealDetail) {
            if let img = pendingCropped {
                MealDetailScreen(image: img, vm: MealViewModel())
            } else {
                Text("No image").foregroundStyle(.secondary)
            }
        }
        .task { await vm.ensurePlanLoaded() }
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


// OnboardingViewModel.swift
extension OnboardingViewModel {
    func ensurePlanLoaded() async {
        if personalPlan != nil { return }
        do {
            let g = try await AuthAPI.shared.getCurrentPlan()
            await MainActor.run {
                self.personalPlan = PersonalPlan(
                    weightUnit: "kg",            // при желании возьми из профиля
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
