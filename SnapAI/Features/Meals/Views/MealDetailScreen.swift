//
//  MealDetailScreen.swift
//  SnapAI
//
//  Created by Isa Melsov on 23/9/25.
//

import SwiftUI

//MARK: - MealDetailScreen
struct MealDetailScreen: View {
    let image: UIImage
    @ObservedObject var vm: MealViewModel
    @State private var showEditor = false
    @State private var apiKey: String = "<YOUR_OPENAI_KEY>"   
    @Environment(\.dismiss) private var dismiss
    @State private var servings = 1
    var onClose: (() -> Void)? = nil
    private let chromeOpacity: Double = 0.6
    @Environment(\.scenePhase) private var scenePhase
    var autoScan: Bool = true
    
    @State private var showAddIngredient = false
    
    @FocusState private var focusedField: Field?
    private enum Field: Hashable { case servings }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            GeometryReader { proxy in
                ScrollView {
                    VStack(spacing: 16) {
                        let title = vm.meal.title.trimmingCharacters(in: .whitespacesAndNewlines)
                        
                        // Фото-«хедер»
                        FixedHeaderImage(image: image, minH: 260, maxH: 480, heightRatio: 0.74)
                            .offset(y: 0)
                        
                        // Карточка с данными
                        VStack(alignment: .leading, spacing: 16) {
                            ZStack(alignment: .leading) {
                                if title.isEmpty {
                                    Text("Meal name")
                                        .foregroundStyle(AppColors.text.opacity(0.75)) // цвет плейсхолдера
                                } else {
                                    Text(title)
                                        .foregroundStyle(AppColors.primary)            // цвет значения
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 16).padding(.vertical, 12)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                            .shadow(color: AppColors.primary.opacity(0.4), radius: 12, x: 0, y: 4)
                            
                            /// Сетка метрик
                            LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: 14) {
                                MetricPill(title: "Callories", value: "\(vm.meal.calories) kcal")
                                StepperPill(
                                    title: "Servings",
                                    value: Binding(
                                        get: { vm.meal.servings },
                                        set: { newVal in vm.update { $0.servings = newVal } }
                                    ),
                                    field: .servings,
                                    focused: $focusedField
                                )
                                MetricPill(title: "Proteins",
                                           value: "\(vm.meal.proteins) g",
                                           badge: .init(kind: .text("P"), color: AppColors.customBlue))
                                
                                MetricPill(title: "Carbohydrates",
                                           value: "\(vm.meal.carbs) g",
                                           badge: .init(kind: .text("C"), color: AppColors.customOrange))
                                MetricPill(title: "Fats",
                                           value: "\(vm.meal.fats) g",
                                           badge: .init(kind: .text("F"), color: AppColors.customGreen))
                                MetricPill(title: "Benefits",
                                           value: "\(vm.meal.benefitScore)/10",
                                           badge: .init(kind: .system("heart.fill"), color: AppColors.customRed))
                            }
                            
                            
                            
                            Button {
                                withAnimation(.spring(response: 0.32, dampingFraction: 0.9)) { showEditor = true }
                            } label: {
                                HStack(spacing: 8) {
                                    AppImages.ButtonIcons.Pen.lightPen
                                        .renderingMode(.template)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 20, height: 20)
                                    
                                    Text("Edit")
                                }
                                .font(.headline)
                                .frame(maxWidth: .infinity, minHeight: 56)
                            }
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
                            
                            
                            
                            Text("Ingredients")
                                .foregroundStyle(AppColors.primary)
                                .font(.title)
                            
                            IngredientList(ingredients: Binding(
                                get: { vm.meal.ingredients },
                                set: { newValue in vm.update { $0.ingredients = newValue } }
                            ))
                            .disabled(true)
                            
                            Spacer()
                            
                            Button { withAnimation(.spring(response: 0.32, dampingFraction: 0.9)) { showEditor = true } } label: {
                                HStack(spacing: 8) {
                                    AppImages.ButtonIcons.share
                                        .renderingMode(.template)
                                        .resizable().scaledToFill()
                                        .frame(width: 20, height: 20)
                                    Text("Share")
                                }
                                .font(.headline)
                                .frame(maxWidth: .infinity, minHeight: 56)
                            }
                            .buttonStyle(.plain)
                            .background(RoundedRectangle(cornerRadius: 28).fill(AppColors.secondary))
                            .overlay(RoundedRectangle(cornerRadius: 28).stroke(AppColors.primary.opacity(0.10), lineWidth: 1))
                            .foregroundStyle(.white)
                            .shadow(color: AppColors.primary.opacity(0.10), radius: 12, x: 0, y: 4)
                            .zIndex(2)
                            
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 36, style: .continuous)
                                .fill(AppColors.background)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 36, style: .continuous)
                                        .stroke(AppColors.primary.opacity(0.10), lineWidth: 1)
                                )
                        )
                        .offset(y: -40)
                        .padding(.bottom, 12)
                        .frame(maxHeight: .infinity)
                    }
                    .frame(minHeight: proxy.size.height)
                }
                .scrollIndicators(.hidden)
            }

            // Лоадер анализа
            if vm.isScanning {
                ProgressView("Analyzing…")
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .padding(.bottom, 24)
            }

            
        }
        .ignoresSafeArea()
        .onReceive(NotificationCenter.default.publisher(for: .dismissToMainFromEdit)) { _ in
            if let onClose { onClose() } else { dismiss() }
        }
        .sheet(isPresented: $showEditor) {
            MealEditSheet(vm: vm, isPresented: $showEditor)
        }
        .sheet(isPresented: $showAddIngredient) {
                    AddIngredientSheet { newIng in
                        vm.update { $0.ingredients.append(newIng) }       // 👈 добавить
                    }
                }
        .toolbarBackground(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                CircleIconButton {
                    if let onClose { onClose() } else { dismiss() }
                                }
                    .foregroundStyle(.black)
                    .opacity(chromeOpacity)
                    
            }
            
            ToolbarItem {
                Text(Date.now.formatted(date: .omitted, time: .shortened))
                    .foregroundStyle(.black)
                    .font(.callout.bold())
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(.white)
                    .clipShape(Capsule())
                    .opacity(chromeOpacity)
            }
        }
        .task {
            vm.restoreFromCache()
            if vm.meal.title.isEmpty && !vm.isScanning {
                vm.scan(image: image)   // без await
            }
        }
        .onChange(of: scenePhase) { phase in
            if phase == .inactive || phase == .background {
                vm.cancelScan()            // ⛔️ отменяем активный аплоад
                // при желании — закрыть редактор и вернуться на главный:
                // showEditor = false
                // if let onClose { onClose() } else { dismiss() }
            }
        }
        .alert("Error", isPresented: Binding(get: { vm.error != nil }, set: { _ in vm.error = nil })) {
            Button("OK", role: .cancel) { }
        } message: { Text(vm.error ?? "") }
    }
}

// MARK: - Ingredients
struct IngredientList: View {
    @Binding var ingredients: [Ingredient]
    var showAddButton: Bool = true
    var onAddTap: () -> Void = {}

    var body: some View {
        VStack(spacing: 12) {
            ForEach(ingredients.indices, id: \.self) { i in
                IngredientRow(ing: $ingredients[i]) {
                    ingredients.remove(at: i)
                }
            }
            if showAddButton {
                            Button(action: onAddTap) {
                                Image(systemName: "plus").font(.title3).padding()
                            }
                            .buttonStyle(CapsuleButtonStyle())
                            .frame(maxWidth: .infinity, alignment: .center)
                        }
        }
    }
}

// MARK: - IngredientRow
private struct IngredientRow: View {
    @Binding var ing: Ingredient
    var onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {

            HStack {
                Text(ing.name)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(AppColors.primary)

                Spacer()

                Text("\(ing.kcal) kcal")
                    .font(.subheadline)
                    .foregroundStyle(AppColors.primary)
            }
            .padding(.horizontal, 16)
            .frame(height: 52)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: 4, y: 0)

            Button(action: onDelete) {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppColors.primary)
                    .frame(width: 44, height: 44)
                    .background(Color.white, in: Circle())
                    .overlay(Circle().stroke(Color.black.opacity(0.08), lineWidth: 1))
                    .overlay(
                        Circle().stroke(
                            LinearGradient(colors: [.white.opacity(0.5), .clear],
                                           startPoint: .topLeading,
                                           endPoint: .bottomTrailing),
                            lineWidth: 1
                        )
                        .blendMode(.plusLighter)
                    )
                    .shadow(color: .black.opacity(0.06), radius: 4, y: 0)
            }
            .buttonStyle(.plain)
            .contentShape(Circle())
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 8)
    }
}




// MARK: - Mocks for Preview
extension Meal {
    static var preview: Meal {
        var m = Meal()
        m.title = "Breakfast plate"
        m.calories = 540
        m.proteins = 25
        m.carbs = 47
        m.fats = 24
        m.benefitScore = 8
        m.ingredients = [
            Ingredient(name: "Egg", kcal: 90),
            Ingredient(name: "Toast", kcal: 130),
            Ingredient(name: "Milk", kcal: 120),
            Ingredient(name: "Nuts", kcal: 200)
        ]
        return m
    }
}

extension MealViewModel {
    static var preview: MealViewModel {
        let vm = MealViewModel()
        vm.meal = .preview
        vm.isScanning = false
        return vm
    }
}

extension UIImage {
    static var previewPlaceholder: UIImage {
        let size = CGSize(width: 800, height: 600)
        return UIGraphicsImageRenderer(size: size).image { ctx in
            UIColor.systemGray5.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }
    }
}



#Preview {
    NavigationStack {
        MealDetailScreen(
            image: UIImage(named: "food1") ?? .previewPlaceholder,
            vm: .preview
        )
    }
}

