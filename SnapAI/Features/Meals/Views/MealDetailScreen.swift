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
    @State private var apiKey: String = "<YOUR_OPENAI_KEY>"   // замени хранением в Keychain
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: 16) {
                    // Фото-«хедер»
                    FixedHeaderImage(image: image)
                        .overlay(alignment: .topLeading) {
                            HStack {
                                Button(action: { dismiss() }) {
                                    Image(systemName: "chevron.left")
                                        .padding(10).background(.ultraThinMaterial).clipShape(Circle())
                                }
                                Spacer()
                                Text(Date.now.formatted(date: .omitted, time: .shortened))
                                    .padding(.horizontal, 10).padding(.vertical, 6)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Capsule())
                            }
                            .padding()
                        }

                    // Карточка с данными
                    VStack(alignment: .leading, spacing: 16) {
                        TextField("Meal name", text: Binding(
                            get: { vm.meal.title },
                            set: { _ in }   // read-only в просмотре
                        ))
                        .disabled(true)
                        .padding()
                        .background(Color.white.opacity(0.7))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                        // Сетка метрик
                        LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: 14) {
                            MetricPill(title: "Calories",       value: "\(vm.meal.calories) kcal")
                            MetricPill(title: "Servings",       value: "1")
                            MetricPill(title: "Proteins",       value: "\(vm.meal.proteins) g")
                            MetricPill(title: "Carbohydrates",  value: "\(vm.meal.carbs) g")
                            MetricPill(title: "Fats",           value: "\(vm.meal.fats) g")
                            MetricPill(title: "Benefits",       value: "\(vm.meal.benefitScore)/10")
                        }

                        Button("Edit") { withAnimation(.spring(response: 0.32, dampingFraction: 0.9)) { showEditor = true } }
                            .buttonStyle(CapsuleButtonStyle(background: Color(.systemGreen).opacity(0.25),
                                                            foreground: .primary))

                        Text("Ingredients").font(.title3.weight(.semibold))

                        VStack(spacing: 12) {
                            ForEach(vm.meal.ingredients) { ing in
                                HStack {
                                    Text(ing.name)
                                    Spacer()
                                    Text("\(ing.kcal) kcal").foregroundColor(.secondary)
                                    Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary).opacity(0.3)
                                }
                                .padding(.horizontal, 14).frame(height: 48)
                                .background(Color.white.opacity(0.7))
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }
                        }

                        Button {
                            // share / export
                        } label: {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                        .buttonStyle(CapsuleButtonStyle(background: Color(.systemGreen).opacity(0.25)))
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 120)
                }
            }
            .background(Color(.systemMint).opacity(0.12).ignoresSafeArea())

            // Лоадер анализа
            if vm.isScanning {
                ProgressView("Analyzing…")
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .padding(.bottom, 24)
            }

            // Редактор, который ПОДНИМАЕТСЯ и перекрывает фото
            if showEditor {
                MealEditSheet(vm: vm, isPresented: $showEditor)
                    .transition(.move(edge: .bottom))
                    .zIndex(1)
            }
        }
        .task {
            // при первом появлении фото — запускаем сканирование
            if vm.meal.title.isEmpty {
                await vm.scan(image: image, apiKey: apiKey)
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

    var body: some View {
        VStack(spacing: 12) {
            ForEach(ingredients.indices, id: \.self) { i in
                IngredientRow(ing: $ingredients[i]) {
                    ingredients.remove(at: i)
                }
            }

            Button {
                withAnimation {
                    ingredients.append(Ingredient(name: "", kcal: 0))
                }
            } label: {
                Image(systemName: "plus").font(.title3).padding()
            }
            .buttonStyle(CapsuleButtonStyle())
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }
}

// MARK: - IngredientRow
private struct IngredientRow: View {
    @Binding var ing: Ingredient
    var onDelete: () -> Void

    var body: some View {
        HStack {
            TextField("Name", text: $ing.name)

            Spacer()

            KcalField(kcal: $ing.kcal)

            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 52)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}


