//
//  MealDetailScreen.swift
//  CropCamera
//
//  Created by Isa Melsov on 22/9/25.
//

import SwiftUI
import UIKit

struct FixedHeaderImage: View {
    let image: UIImage
    static let height: CGFloat = 260

    var body: some View {
        ZStack {                // фон, если картинка уже узкая/высокая
            Color.black
            Image(uiImage: image)
                .resizable()
                .interpolation(.high)
                .antialiased(true)
                .scaledToFill() // центр-кроп внутри фиксированного контейнера
        }
        .frame(maxWidth: .infinity)
        .frame(height: Self.height)
        .clipped()
    }
}


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

struct MealEditSheet: View {
    @ObservedObject var vm: MealViewModel
    @Binding var isPresented: Bool

    @State private var draft = Meal()

    var body: some View {
        VStack(spacing: 16) {
            grabber

            Text("Edit mode")
                .font(.title2.weight(.semibold))

            ScrollView {
                form
            }

            Button("Сохранить") {
                vm.meal = draft
                withAnimation(.spring(response: 0.32, dampingFraction: 0.9)) { isPresented = false }
            }
            .buttonStyle(CapsuleButtonStyle(background: Color(.systemGreen),
                                             foreground: .white))
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .background(Color(.systemMint).opacity(0.12).ignoresSafeArea())
        .onAppear { draft = vm.meal }
        .gesture(
            DragGesture().onEnded { value in
                if value.translation.height > 100 {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.9)) { isPresented = false }
                }
            }
        )
    }

    // MARK: - Subviews

    private var grabber: some View {
        Capsule()
            .frame(width: 44, height: 5)
            .foregroundStyle(Color.secondary.opacity(0.3))
            .padding(.top, 8)
    }

    private var form: some View {
        VStack(alignment: .leading, spacing: 16) {
            TextField("Meal name", text: $draft.title)
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
                .font(.title3.weight(.semibold))

            IngredientList(ingredients: $draft.ingredients)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
}

// MARK: - Ingredients

private struct IngredientList: View {
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

private struct KcalField: View {
    @Binding var kcal: Int

    var body: some View {
        TextField("kcal", text: Binding(
            get: { String(kcal) },
            set: { val in
                let digits = val.filter(\.isNumber)
                kcal = Int(digits) ?? 0
            }
        ))
        .keyboardType(.numberPad)
        .multilineTextAlignment(.trailing)
        .frame(width: 70)
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
                .keyboardType(.numberPad)
                Spacer()
                Text(unit).foregroundColor(.secondary)
            }
            .padding(.vertical, 12).padding(.horizontal, 14)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }



struct MetricPill: View {
    let title: String
    let value: String
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.caption).foregroundColor(.secondary)
            Text(value)
                .font(.headline)
                .padding(.vertical, 10).padding(.horizontal, 14)
                .background(Color(.systemBackground))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color.secondary.opacity(0.15), lineWidth: 1))
        }
    }
}

struct AddMealContainer: View {
    @StateObject private var coordinator = BridgingCoordinator()
    @StateObject private var vm = MealViewModel()

    var body: some View {
        Group {
            if let image = coordinator.capturedImage {
                MealDetailScreen(image: image, vm: vm)   // 👉 экран из дизайна
            } else {
                HostedCameraView(coordinator: coordinator)
                    .ignoresSafeArea()
            }
        }
    }
}

@MainActor
final class MealViewModel: ObservableObject {
    @Published var meal = Meal()
    @Published var isScanning = false
    @Published var error: String?

    // положи ключ в Keychain и передай сюда
    func scan(image: UIImage, apiKey: String) async {
        isScanning = true; error = nil
        do {
            let result = try await FoodScanService.scan(image: image, apiKey: apiKey)
            self.meal = result
        } catch {
            self.error = error.localizedDescription
        }
        isScanning = false
    }
}


struct FoodScanService {
    struct ScanResult: Codable { let meal: Meal }

    static func scan(image: UIImage, apiKey: String) async throws -> Meal {
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        let jpeg = image.jpegData(compressionQuality: 0.9) ?? Data()
        let b64 = jpeg.base64EncodedString()

        // Просим СТРОГО вернуть JSON по нашей схеме
        let prompt = """
        You are a nutrition expert. Return ONLY minified JSON for a single meal with keys:
        { "title": String, "calories": Int, "proteins": Int, "fats": Int, "carbs": Int, "servings": Int,
          "benefitScore": Int (0-10),
          "ingredients": [ { "name": String, "kcal": Int }, ... ] }.
        Values in grams for macros. If uncertain, best estimate.
        """

        let body: [String: Any] = [
            "model": "gpt-4o-mini",
            "temperature": 0.2,
            "messages": [
                ["role": "system", "content": prompt],
                ["role": "user",
                 "content": [
                    ["type": "text", "text": "What is in this photo? Return JSON as specified."],
                    ["type": "image_url",
                     "image_url": ["url": "data:image/jpeg;base64,\(b64)"]]
                 ]
                ]
            ]
        ]

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await URLSession.shared.data(for: req)

        // ✅ правильные модели ответа OpenAI Chat Completions
        struct APIResponse: Decodable {
            struct Choice: Decodable {
                struct Message: Decodable {
                    let content: String
                }
                let message: Message
            }
            let choices: [Choice]
        }

        let resp = try JSONDecoder().decode(APIResponse.self, from: data)

        // берём текст, срезаем возможные код-фенсы
        var content = resp.choices.first?.message.content ?? ""
        if content.hasPrefix("```") {
            content = content
                .replacingOccurrences(of: "```json", with: "")
                .replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }

        guard let jsonData = content.data(using: .utf8) else {
            throw NSError(domain: "Scan", code: -2, userInfo: [NSLocalizedDescriptionKey: "Invalid content"])
        }

        return try JSONDecoder().decode(Meal.self, from: jsonData)

    }
}


struct Ingredient: Identifiable, Codable, Hashable {
    var id: UUID = .init()
    var name: String
    var kcal: Int
}

struct Meal: Codable {
    var title: String = ""
    var calories: Int = 0
    var proteins: Int = 0
    var fats: Int = 0
    var carbs: Int = 0
    var servings: Int = 1
    var benefitScore: Int = 5   // 0…10 на макете "5/10"
    var ingredients: [Ingredient] = []
}

extension Meal {
    static let mock = Meal(
        title: "Teriyaki chicken with rice",
        calories: 241, proteins: 50, fats: 32, carbs: 150, servings: 1, benefitScore: 5,
        ingredients: [
            .init(name: "Chicken breast", kcal: 330),
            .init(name: "Teriyaki sauce", kcal: 210),
            .init(name: "Vegetable oil", kcal: 270),
            .init(name: "Rice", kcal: 340)
        ]
    )
}

@MainActor
extension MealViewModel {
    static var preview: MealViewModel {
        let vm = MealViewModel()
        vm.meal = .mock
        return vm
    }
}

extension UIImage {
    static func solid(color: UIColor, size: CGSize = .init(width: 900, height: 600)) -> UIImage {
        let r = UIGraphicsImageRenderer(size: size)
        return r.image { ctx in
            color.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }
    }
}

#Preview("MealDetail") {
    MealDetailScreen(
        image: .solid(color: .systemGray5),  // или UIImage(named: "yourAsset") ?? .solid(...)
        vm: .preview
    )
}
