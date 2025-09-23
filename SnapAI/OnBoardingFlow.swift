//
//  OnBoardingFlow.swift
//  SnapAI
//
//  Created by Isa Melsov on 16/9/25.
//

import SwiftUI

enum SelectedGender: String, Codable { case male, female, other }

//MARK: - BackButton
struct BackButton: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Button {
            dismiss()
        } label: {
            AppImages.ButtonIcons.arrowRight
                .resizable()
                .frame(width: 12, height: 20)
                .rotationEffect(.degrees(180))
                .padding()
        }
    }
}



//MARK: - BubbleSegmentedControl
struct BubbleSegmentedControl: View {
    @ObservedObject var vm: OnboardingViewModel
    var height: CGFloat = 44
    
    var body: some View {
        HStack(spacing: 12) {
            seg("Imperial", .imperial)
            
            seg("Metric", .metric)
        }
        .frame(maxWidth: .infinity)
        .padding(8)
        .background(AppColors.background)
        .clipShape(RoundedRectangle(cornerRadius: height/2))
        .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 2)
        .frame(height: height)
    }
    
    @ViewBuilder
    private func seg(_ title: String, _ unit: UnitSystem) -> some View {
        let isSelected = vm.data.unit == unit
        
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                vm.data.unit = unit
            }
        } label: {
            Text(title)
                .frame(maxWidth: .infinity)
                .font(.system(size: 16, weight: isSelected ? .bold : .regular))
                .foregroundColor(isSelected ? .white : AppColors.text)
            // в исходнике minHeight = 24 — подгоним относительно общей высоты
                .frame(maxWidth: .infinity, minHeight: height - 20)
                .background(isSelected ? AppColors.primary : Color.clear)
                .clipShape(Capsule())
                .contentShape(Rectangle())
        }
    }
}


//MARK: - ThickLinearProgressViewStyle
struct ThickLinearProgressViewStyle: ProgressViewStyle {
    var height: CGFloat = 12
    var cornerRadius: CGFloat = 6
    var fillColor: Color = .green
    var trackColor: Color = .gray.opacity(0.4)
    
    func makeBody(configuration: Configuration) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // фон (трек)
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(trackColor)
                    .frame(height: height)
                
                // прогресс
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(fillColor)
                    .frame(width: geo.size.width * CGFloat(configuration.fractionCompleted ?? 0),
                           height: height)
            }
        }
        .frame(height: height)
    }
}


struct OnboardingFlow: View {
    @StateObject private var vm: OnboardingViewModel
    
    init(onFinished: @escaping () -> Void) {
        // подставьте реальный baseURL и токен (из логина)
//        let repo = APIRepository(baseURL: URL(string: "https://api.yourserver.com")!,
//                                 authToken: "<JWT>")
            let repo = LocalRepository()  // ⬅️ сюда
            _vm = StateObject(wrappedValue: OnboardingViewModel(repository: repo,
                                                                onFinished: onFinished))
    }
    
    var body: some View {
        NavigationStack { StartStep(vm: vm) }
    }
}
//MARK: - StartStep
struct StartStep: View {
    @ObservedObject var vm: OnboardingViewModel
    @State private var focalYOffset: CGFloat = 0
    var body: some View {
        GeometryReader { geo in
            ZStack {
                VStack(spacing: 0) {
                    AppImages.Other.food1
                        .resizable()
                        .scaledToFill()
                        .frame(height: geo.size.height * 0.80)
                        .clipped()
                        .offset(y: focalYOffset)
                    Spacer(minLength: 0)
                }
                VStack(spacing: 16) {
                    
                    Spacer()
                    
                    Group {
                        Text("Welcome to ")
                            .fontWeight(.regular)
                            .foregroundColor(AppColors.primary) +
                        Text("Snap AI")
                            .fontWeight(.bold)
                            .foregroundColor(AppColors.primary)
                    }
                    .font(.system(size: 36))
                    
                    Spacer()
                    
                    Text("Count calories from a photo in just 1 click")
                        .multilineTextAlignment(.center)
                        .foregroundColor(AppColors.text)
                    
                    NavigationLink(destination: GenderStep(vm: vm)) {
                        Text("Get Started")
                            .font(.headline)
                            .frame(maxWidth: .infinity, minHeight: 56)
                            .foregroundColor(.white)
                            .background(AppColors.secondary)
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                    }
                    .padding(.bottom, 28)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
                .frame(height: geo.size.height * 0.42)
                .frame(maxWidth: .infinity)
                .background(AppColors.background)
                .clipShape(RoundedRectangle(cornerRadius: 28))
                .shadow(color: .black.opacity(0.08), radius: 12, y: -2)
                .offset(y: 8)
                .frame(maxHeight: .infinity, alignment: .bottom)
            }
            .ignoresSafeArea()
        }
    }
}

//MARK: - GenderStep
struct GenderStep: View {
    @ObservedObject var vm: OnboardingViewModel
    @State private var selected: Gender = .male   // текущий выбор
    @State private var currentImage = AppImages.Gender.male
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Select your gender")
                .font(.system(size: 24, weight: .regular))
                .foregroundStyle(AppColors.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 26)
            
            currentImage
                .resizable()
                .scaledToFit()
                .frame(height: 300)
                .padding(.top, -8)
            
            HStack(spacing: 16) {
                genderButton(.male, title: "Male")
                genderButton(.female, title: "Female")
            }
            .padding(.horizontal, 26)
            
            genderButton(.other, title: "Other")
                .padding(.horizontal, 26)
            
            Spacer()
            
            NavigationLink(destination: WeightHeightStep(vm: vm)) {
                Text("Next")
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 60)
                    .foregroundColor(.white)
                    .background(AppColors.secondary)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
            }
            .padding(.horizontal, 26)
            .padding(.bottom, 28)
        }
        .background(AppColors.background.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) { BackButton() }
            ToolbarItem(placement: .principal) {
                ProgressView(value: 1, total: 5)
                    .progressViewStyle(
                        ThickLinearProgressViewStyle(
                            height: 10, cornerRadius: 7,
                            fillColor: AppColors.primary, trackColor: AppColors.secondary
                        )
                    )
                    .frame(width: UIScreen.main.bounds.width * 0.6, height: 10)
                    .padding(.top, 2)
            }
        }
    }
    
    // MARK: - UI helpers
    
    @ViewBuilder
    private func genderButton(_ gender: Gender, title: String) -> some View {
        let selectedState = (selected == gender)
        
        Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                selected = gender
                vm.data.gender = gender
                switch gender {
                case .male:   currentImage = AppImages.Gender.male
                case .female: currentImage = AppImages.Gender.female
                case .other:  currentImage = AppImages.Gender.other
                }
            }
        } label: {
            Text(title)
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(selectedState ? .white : AppColors.text)
                .frame(maxWidth: .infinity, minHeight: 60)
                .background(selectedState ? AppColors.secondary : Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppColors.secondary, lineWidth: 1)
                )
                .shadow(color: .black.opacity(selectedState ? 0.0 : 0.15), radius: 3, y: 2)
        }
    }
}

//MARK: - WeightHeightStep
struct WeightHeightStep: View {
    @ObservedObject var vm: OnboardingViewModel
    @State private var weightText = ""
    @State private var heightText = ""
    @State private var unit: UnitSystem = .imperial
    var body: some View {
        VStack(spacing: 16) {
            Text("Weight and Height")
                .font(.system(size: 24, weight: .regular))
                .foregroundStyle(AppColors.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 26)
            
            Spacer()
            
            BubbleSegmentedControl(vm: vm, height: 48)
                .padding(.horizontal, 26)
            
            
            Text("Weight")
                .font(.system(size: 24, weight: .regular))
                .foregroundStyle(AppColors.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 26)
            
            UnitTextField(vm: vm, placeholder: "Your weight", text: $weightText, kind: .weight)
            
                .padding(.horizontal, 26)
            
            
            
            
            Text("Height")
                .font(.system(size: 24, weight: .regular))
                .foregroundStyle(AppColors.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 26)
            
            UnitTextField(vm: vm, placeholder: "Your height", text: $heightText, kind: .height)
            
                .padding(.horizontal, 26)
            
            Spacer()
            
            NavigationLink(destination: DateOfBirthStep(vm: vm)) {
                Text("Next")
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 60)
                    .foregroundColor(.white)
                    .background(AppColors.secondary)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
            }
            .padding(.horizontal, 26)
            .padding(.bottom, 28)
            .onAppear {
                vm.data.weight = Double(weightText)
                vm.data.height = Double(heightText)
            }
        }
        .padding()
        .background(AppColors.background.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) { BackButton() }
            ToolbarItem(placement: .principal) {
                ProgressView(value: 2, total: 5)
                    .progressViewStyle(
                        ThickLinearProgressViewStyle(
                            height: 10, cornerRadius: 7,
                            fillColor: AppColors.primary, trackColor: AppColors.secondary
                        )
                    )
                    .frame(width: UIScreen.main.bounds.width * 0.6, height: 10)
                    .padding(.top, 2)
            }
        }
    }
}

//MARK: - UnitTextField
struct UnitTextField: View {
    @ObservedObject var vm: OnboardingViewModel   // <-- учитываем vm
    let placeholder: String
    @Binding var text: String
    
    enum Kind { case weight, height }
    
    let kind: Kind
    
    private var unit: String {
        switch kind {
        case .weight: return vm.data.unit == .imperial ? "lbs" : "kg"
        case .height: return vm.data.unit == .imperial ? "ft"  : "cm"
        }
    }
    
    var body: some View {
        HStack {
            TextField(placeholder, text: $text)
                .keyboardType(.decimalPad)
                .foregroundColor(AppColors.text)
            
            Text(unit)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppColors.primary)
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, minHeight: 56)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.black.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
        // необязательная фильтрация: оставляем только цифры/точку/запятую
        .onChange(of: text) { v in
            let filtered = v.filter { "0123456789.,".contains($0) }
            if filtered != v { text = filtered }
        }
    }
}

//MARK: - DateOfBirthStep
struct DateOfBirthStep: View {
    @ObservedObject var vm: OnboardingViewModel
    @State private var selectedDate: Date?
    var body: some View {
        VStack {
            Text("Date of birth")
                .font(.system(size: 24, weight: .regular))
                .foregroundStyle(AppColors.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 40)
            
            Spacer()
            
            DateWheelPicker()
            
            Spacer()
            
            NavigationLink(destination: LifestyleStep(vm: vm)) {
                Text("Next")
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 60)
                    .foregroundColor(.white)
                    .background(AppColors.secondary)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 28)
            .onAppear {
                //                    vm.data.weight = Double(weightText)
                //                    vm.data.height = Double(heightText)
            }
            
        }
        .padding()
        .background(AppColors.background.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) { BackButton() }
            ToolbarItem(placement: .principal) {
                ProgressView(value: 3, total: 5)
                    .progressViewStyle(
                        ThickLinearProgressViewStyle(
                            height: 10, cornerRadius: 7,
                            fillColor: AppColors.primary, trackColor: AppColors.secondary
                        )
                    )
                    .frame(width: UIScreen.main.bounds.width * 0.6, height: 10)
                    .padding(.top, 2)
            }
        }
    }
}


//MARK: - LifestyleStep
struct LifestyleStep: View {
    @ObservedObject var vm: OnboardingViewModel
    @State private var selected: Lifestyle = .sedentary
    @State private var currentImage = AppImages.Activity.sedantary
    var body: some View {
        VStack {
            Text("Activity")
                .font(.system(size: 24, weight: .regular))
                .foregroundStyle(AppColors.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 26)
            
            Spacer()
            
            currentImage
                .resizable()
                .scaledToFit()
                .frame(height: 220)
                .padding(.vertical)
            
            VStack(spacing: 16) {
                lifeStyleButton(.sedentary, title: "Sedentary lifestyle")
                lifeStyleButton(.normal, title: "Normal lifestyle")
                lifeStyleButton(.active, title: "Active lifestyle")
            }
            .padding([.horizontal, .vertical], 26)
            
            Spacer()
            
            NavigationLink(destination: GoalStep(vm: vm)) {
                Text("Next")
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 60)
                    .foregroundColor(.white)
                    .background(AppColors.secondary)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
            }
            .padding(.horizontal, 26)
            .padding(.bottom, 28)
        }
        .padding()
        .background(AppColors.background.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) { BackButton() }
            ToolbarItem(placement: .principal) {
                ProgressView(value: 4, total: 5)
                    .progressViewStyle(
                        ThickLinearProgressViewStyle(
                            height: 10, cornerRadius: 7,
                            fillColor: AppColors.primary, trackColor: AppColors.secondary
                        )
                    )
                    .frame(width: UIScreen.main.bounds.width * 0.6, height: 10)
                    .padding(.top, 2)
            }
        }
    }
    
    @ViewBuilder
    private func lifeStyleButton(_ lifeStyle: Lifestyle, title: String) -> some View {
        let selectedState = (selected == lifeStyle)
        
        Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                selected = lifeStyle
                vm.data.lifestyle = lifeStyle
                switch lifeStyle {
                case .sedentary: currentImage = AppImages.Activity.sedantary
                case .normal: currentImage = AppImages.Activity.normal
                case .active:  currentImage = AppImages.Activity.active
                }
            }
        } label: {
            Text(title)
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(selectedState ? .white : AppColors.text)
                .frame(maxWidth: .infinity, minHeight: 60)
                .background(selectedState ? AppColors.secondary : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppColors.secondary, lineWidth: 1)
                )
                .shadow(color: .black.opacity(selectedState ? 0.0 : 0.15), radius: 3, y: 2)
        }
    }
}


//MARK: - GoalStep
struct GoalStep: View {
    @ObservedObject var vm: OnboardingViewModel
    @State private var desiredWeightText = ""
    @State private var selected: Goal = .lose
    var body: some View {
        VStack(spacing: 16) {
            
            Text("Goal")
                .font(.system(size: 24, weight: .regular))
                .foregroundStyle(AppColors.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 26)
            // картинка по полу
            vm.data.genderImage
                .resizable()
                .scaledToFit()
                .frame(height: 220)
            
            
            HStack(spacing: 6) {
                goalButton(.lose, title: "Lose weight")
                goalButton(.gain, title: "Gain weight")
                goalButton(.maintain, title: "Maintain weight")
            }
            .padding([.horizontal, .vertical], 26)
            
            Spacer()
            
            // только желаемый вес (юниты из vm.data.unit)
            UnitTextField(vm: vm,
                          placeholder: "Enter your desired weight",
                          text: $desiredWeightText,
                          kind: .weight)
            .padding(.horizontal, 26)
            .onChange(of: desiredWeightText) { v in
                vm.data.desiredWeight = v
                    .replacingOccurrences(of: ",", with: ".")
                    .doubleValue
            }
            
            
            Spacer()
            
            // дальше идём на экран Rate (оценка в App Store)
            NavigationLink {
                RateStep(vm: vm)   // <- твой экран с оценкой приложения
            } label: {
                Text("Next")
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 56)
                    .foregroundColor(.white)
                    .background(AppColors.secondary)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
            }
            .simultaneousGesture(TapGesture().onEnded { vm.saveDraft() })
            .padding(.horizontal, 26)
            .padding(.top, 8)
        }
        .padding(.top, 8)
        .background(AppColors.background.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) { BackButton() }
            ToolbarItem(placement: .principal) {
                ProgressView(value: 5.0, total: 5.0)
                    .progressViewStyle(
                        ThickLinearProgressViewStyle(
                            height: 10, cornerRadius: 7,
                            fillColor: AppColors.primary, trackColor: AppColors.secondary
                        )
                    )
                    .frame(width: UIScreen.main.bounds.width * 0.6, height: 10)
                    .padding(.top, 2)
            }
        }
    }
    
    @ViewBuilder
    private func goalButton(_ goal: Goal, title: String) -> some View {
        let selectedState = (selected == goal)
        
        Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                selected = goal
                vm.data.goal = goal
            }
        } label: {
            Text(title)
                .font(.system(size: 14, weight: selectedState ? .semibold : .regular))
                .foregroundColor(selectedState ? .white : AppColors.primary)
                .frame(maxWidth: .infinity, minHeight: 40)
                .background(selectedState ? AppColors.primary : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(AppColors.primary, lineWidth: 1)
                )
                .shadow(color: .black.opacity(selectedState ? 0.0 : 0.15), radius: 3, y: 2)
        }
    }
}

//MARK: -  SubmittingOverlay

// SubmittingOverlay.swift
import SwiftUI

struct SubmittingOverlay: View {
    let title: String
    let subtitle: String?
    @Binding var progress: Double          // 👈 привязываем прогресс 0...1
    var onCancel: (() -> Void)?

    var body: some View {
        ZStack {
            AppColors.background.opacity(0.98).ignoresSafeArea()

            VStack(spacing: 24) {
                // ⬇️ твой кастомный круговой прогресс
                ZStack {
                    Circle()
                        .stroke(lineWidth: 24)
                        .frame(width: 300, height: 300)
                        .foregroundStyle(
                            LinearGradient(gradient: Gradient(colors: [AppColors.background, AppColors.primary]),
                                           startPoint: .top, endPoint: .bottomLeading)
                        )
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 10, y: 10)

                    Circle()
                        .trim(from: 0, to: progress) // 👈 ПРОГРЕСС
                        .stroke(style: StrokeStyle(lineWidth: 24, lineCap: .round))
                        .frame(width: 300, height: 300)
                        .rotationEffect(.degrees(-90))
                        .foregroundStyle(
                            LinearGradient(gradient: Gradient(colors: [AppColors.secondary, AppColors.primary]),
                                           startPoint: .top, endPoint: .bottomLeading)
                        )
                        .animation(.easeInOut(duration: 0.25), value: progress)

                    Circle()
                        .frame(width: 220, height: 220)
                        .foregroundStyle(
                            LinearGradient(gradient: Gradient(colors: [AppColors.primary, AppColors.secondary]),
                                           startPoint: .top, endPoint: .bottom)
                        )

                    Circle()
                        .stroke(style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 225, height: 225)
                        .foregroundStyle(
                            LinearGradient(gradient: Gradient(colors: [AppColors.background, AppColors.primary]),
                                           startPoint: .top, endPoint: .bottomLeading)
                        )
                        .shadow(color: .black.opacity(0.4), radius: 10, x: 10, y: 10)

                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 32, weight: .semibold, design: .default))
                        .foregroundColor(.white)
                        .padding()
                }

                // подписи
                Text(title)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(AppColors.primary)

                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(AppColors.primary.opacity(0.7))
                }

                if let onCancel {
                    Button("Отмена", action: onCancel)
                        .padding(.top, 4)
                }
            }
            .padding()
        }
    }
}



//MARK: - RateStep
import StoreKit

struct RateStep: View {
    @ObservedObject var vm: OnboardingViewModel
    @State private var currentRating = 0
    @State private var showFeedbackForm = false
    @State private var showSubmitting = false
    @State private var showPlan = false           // 👈 добавили
    @State private var showError = false          // 👈 добавили
    @State private var errorMsg = ""              // 👈 добавили
    
    @Environment(\.openURL) private var openURL
    private let appID = "1234567890" // TODO: реальный

    var body: some View {
        ZStack {
            content
        }
        .fullScreenCover(isPresented: $showSubmitting) {
            SubmittingOverlay(
                title: "Creating your personalized meal\nand workout plan",
                subtitle: "Analyzing your responses...",
                progress: $vm.progress,
                onCancel: nil // обычно отмена не нужна
            )
            .task { await vm.finish() }
        }
        .fullScreenCover(isPresented: $showPlan) {     // 👈 показываем PlanScreen
                    if let plan = vm.personalPlan {
                        PlanScreen(plan: plan)
                    } else {
                        Text("Нет данных плана")
                    }
                }
        .onChange(of: vm.phase) { new in
            switch new {
                        case .ready:
                            showSubmitting = false
                            showPlan = true
                        case .failed(let msg):
                            showSubmitting = false
                            errorMsg = msg
                            showError = true
                        default:
                            break
                        }
        }
        .alert("Ошибка", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMsg)
        }
    }

    private var isError: Bool {
        if case .failed = vm.phase { return true }
        return false
    }

    private var content: some View {
        VStack {
            StarLine(rating: $currentRating)
            Text("Snap AI helps you reach your goals")
                .foregroundStyle(AppColors.primary)
                .font(.system(size: 20, weight: .regular))
                .padding()
            Spacer()
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ReviewCards(); ReviewCards(); ReviewCards()
                    Spacer(minLength: 16)
                }
            }
            .padding(.trailing, -16)
            Spacer()
            Button { rateAndProceed() } label: {
                Text("Rate")
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 60)
                    .foregroundColor(.white)
                    .background(AppColors.secondary)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
            }
            .padding(.bottom, 28)
        }
        .padding()
        .background(AppColors.background.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: proceedNext) { BackButton() }
            }
            ToolbarItem(placement: .principal) {
                Text("Rate Us")
                    .font(.system(size: 24, weight: .regular))
                    .foregroundStyle(AppColors.primary)
            }
        }
        // форма фидбэка при низкой оценке
        .sheet(isPresented: $showFeedbackForm) {
            FeedbackSheet(
                rating: currentRating,
                onSend: { _ in proceedNext() },
                onSkip: { proceedNext() }
            )
        }
    }

    private func rateAndProceed() {
        if currentRating >= 4 {
            if let url = URL(string: "https://apps.apple.com/app/id\(appID)?action=write-review") {
                openURL(url)
            } else {
                requestStoreReview()
            }
            // без ожидания колбэков → идём дальше
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                proceedNext()
            }
        } else {
            showFeedbackForm = true
        }
    }

    private func proceedNext() {
        // показываем крутилку и стартуем финализацию
        showSubmitting = true
        vm.phase = .submitting
    }

    private func requestStoreReview() {
        if let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene }).first {
            SKStoreReviewController.requestReview(in: scene)
        }
    }
}


//MARK: - RootView
struct RootView: View {
    @StateObject private var vm = OnboardingViewModel(
        repository: LocalRepository(),
        onFinished: {}
    )
    @State private var path = NavigationPath()

    var body: some View {
        AppNavigationContainer {
            NavigationStack(path: $path) {
                GoalStep(vm: vm)
                    .navigationDestination(for: Route.self) { route in
                        switch route {
                        case .rate: RateStep(vm: vm)
                        case .plan:
                            if let plan = vm.personalPlan {
                                PlanScreen(plan: plan)  // «экран два»
                            } else {
                                Text("Нет данных плана")
                            }
                        }
                    }
                    .onChange(of: vm.phase) { new in
                        switch new {
                        case .goal: break
                        case .rate: path.append(Route.rate)
                        case .submitting: break
                        case .ready: path.append(Route.plan)
                        case .failed: break
                        }
                    }
            }
        }
    }

    enum Route: Hashable { case rate, plan }
}



//MARK: - FeedbackSheet
struct FeedbackSheet: View {
    let rating: Int
    var onSend: (String) -> Void
    var onSkip: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var text: String = ""

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                Text("What could we improve?")
                    .font(.headline)

                TextEditor(text: $text)
                    .frame(minHeight: 140)
                    .padding(8)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                Spacer()

                Button {
                    dismiss()
                    onSend(text.trimmingCharacters(in: .whitespacesAndNewlines))
                } label: {
                    Text("Send feedback")
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .foregroundColor(.white)
                        .background(AppColors.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Button {
                    dismiss()
                    onSkip()
                } label: {
                    Text("Skip")
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .foregroundColor(AppColors.primary)
                        .background(Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding()
            .navigationTitle("Your feedback")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}



//MARK: - ReviewCards
struct ReviewCards: View {
    var body: some View {
        VStack {
            HStack {
                Image("review1")
                    .resizable()
                    .frame(width: 60, height: 60)
                    .padding(.vertical, 24)
                
                Text("Michael Brooks")
                    .font(.system(size: 12, weight: .medium))
            }
            
            Text("I was shocked! I just snapped a\nphoto of my food, and Snap AI\ninstantly counted the calories!")
                .font(.system(size: 12, weight: .regular))
                .padding()
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
            
            HStack {
                ForEach(0..<5) { _ in
                    Image(systemName: "star.fill").foregroundColor(Color.yellow)
                }
            }
            .padding(.vertical, 24)
        }
        .padding(.horizontal, 4)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

//MARK: - StarLine
struct StarLine: View {
    @Binding var rating: Int
    var maximumRating: Int = 5
    var offColor = Color.gray
    var onColor = Color.yellow
    
    var height: CGFloat = 44
    
    var body: some View {
        HStack {
            ForEach(1..<maximumRating + 1, id: \.self) { number in
                (number <= rating ? AppImages.ButtonIcons.Star.activeStar
                 : AppImages.ButtonIcons.Star.inactiveStar)
                .resizable()
                .frame(width: 24, height: 24)
                .onTapGesture {
                        withAnimation(.interactiveSpring) {
                            rating = number
                        }
                    }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: height/2))
        .overlay(
            RoundedRectangle(cornerRadius: height/2)
                .stroke(AppColors.primary, lineWidth: 1)
        )
        .frame(height: height)
        
        .font(.largeTitle)
    }
}


//MARK: - Time Picker
// MARK: Универсальная колонка-колесо c "пилюлей" по центру
// MARK: iOS15-compatible WheelPicker with centered pill and snapping
struct WheelPicker<ItemView: View>: View {
    @Binding var selectedIndex: Int
    let count: Int
    let row: (Int, Bool) -> ItemView
    
    var columnWidth: CGFloat = 140
    var itemHeight: CGFloat = 58
    var visibleRows: Int = 5
    var pillHeight: CGFloat = 36
    var pillHorizontalInset: CGFloat = 16
    var tiltDegrees: Double = 40
    
    @State private var containerMidY: CGFloat = .zero
    @State private var isDragging = false
    @State private var pendingIndex: Int? = nil     // 👈 сюда складываем ближайший индекс во время скролла
    
    private var rowsAbove: Int { (visibleRows - 1) / 2 }
    private var topBottomInset: CGFloat { CGFloat(rowsAbove) * itemHeight }
    
    private let wheelSpace = "wheelSpace" // 👈
    
    var body: some View {
        GeometryReader { _ in
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        ForEach(0..<count, id: \.self) { i in
                            let isSel = i == selectedIndex
                            let diff = Double(i - selectedIndex)
                            
                            row(i, isSel)
                                .frame(height: itemHeight)
                                .rotation3DEffect(
                                    .degrees((-tiltDegrees / Double(max(rowsAbove, 1))) * diff),
                                    axis: (x: 1, y: 0, z: 0),
                                    perspective: 0.6
                                )
                                .opacity(isSel ? 1.0 : 0.65)
                                .background(
                                    GeometryReader { rowGeo in
                                        Color.clear.preference(
                                            key: RowDistanceKey.self,
                                            value: [i: abs(rowGeo.frame(in: .named(wheelSpace)).midY - containerMidY)]
                                        )
                                    }
                                )
                                .id(i)
                        }
                    }
                    .padding(.vertical, topBottomInset)
                }
                .background(
                    GeometryReader { geo in
                        Color.clear
                            .onAppear { containerMidY = geo.frame(in: .named(wheelSpace)).midY }
                            .onChange(of: geo.frame(in: .named(wheelSpace)).midY) { containerMidY = $0 }
                    }
                )
                .coordinateSpace(name: wheelSpace)
                .gesture(
                    DragGesture()
                        .onChanged { _ in
                            if !isDragging { isDragging = true }
                        }
                        .onEnded { _ in
                            isDragging = false
                            let target = pendingIndex ?? selectedIndex
                            pendingIndex = nil
                            if target != selectedIndex { selectedIndex = target }
                            
                            // ✅ haptic feedback
                            let gen = UIImpactFeedbackGenerator(style: .light)
                            gen.impactOccurred()
                            
                            withAnimation(.easeOut(duration: 0.2)) {
                                proxy.scrollTo(target, anchor: .center)
                            }
                        }
                )
                .onAppear {
                    proxy.scrollTo(selectedIndex, anchor: .center)
                }
                .onChange(of: selectedIndex) { new in
                    guard !isDragging else { return }
                    withAnimation(.easeOut(duration: 0.2)) {
                        proxy.scrollTo(new, anchor: .center)
                    }
                }
                .onPreferenceChange(RowDistanceKey.self) { distances in
                    guard !distances.isEmpty else { return }
                    if let nearest = distances.min(by: { $0.value < $1.value })?.key {
                        if isDragging {
                            // во время скролла просто запоминаем — не дёргаем прокрутку
                            pendingIndex = nearest
                        } else if nearest != selectedIndex {
                            selectedIndex = nearest
                        }
                    }
                }
            }
        }
        .frame(width: columnWidth, height: itemHeight * CGFloat(visibleRows))
        .background(alignment: .center) {
            Capsule()
                .fill(AppColors.primary)
                .frame(height: pillHeight)
                .padding(.horizontal, pillHorizontalInset)
                .allowsHitTesting(false)
        }
    }
}

private struct RowDistanceKey: PreferenceKey {
    static var defaultValue: [Int: CGFloat] = [:]
    static func reduce(value: inout [Int: CGFloat], nextValue: () -> [Int: CGFloat]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

struct DateWheelPicker: View {
    @State private var month = 0
    @State private var day = 0        // 0 -> "01"
    @State private var year = 2
    
    private let months = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"]
    private let days = (1...31).map { String(format: "%02d", $0) }
    private let years = (1940...Calendar.current.component(.year, from: Date())).map(String.init)
    
    var body: some View {
        HStack(spacing: 20) {
            WheelPicker(selectedIndex: $month, count: months.count) { i, isSel in
                Text(months[i])
                    .font(.system(size: 22, weight: isSel ? .bold : .regular))
                    .foregroundColor(isSel ? .white : AppColors.primary)
                    .frame(maxWidth: .infinity)
            }
            
            WheelPicker(selectedIndex: $day, count: days.count,
                        row: { i, isSel in
                Text(days[i])
                    .font(.system(size: 22, weight: isSel ? .bold : .regular))
                    .foregroundColor(isSel ? .white : AppColors.primary)
                    .frame(maxWidth: .infinity)
            })
            .modifier(ColumnWidth(width: 100))
            
            WheelPicker(selectedIndex: $year, count: years.count) { i, isSel in
                Text(years[i])
                    .font(.system(size: 22, weight: isSel ? .bold : .regular))
                    .foregroundColor(isSel ? .white : AppColors.primary)
                    .frame(maxWidth: .infinity)
            }
            .modifier(ColumnWidth(width: 130))
        }
        .padding(.horizontal, 16)
    }
    
    struct ColumnWidth: ViewModifier {
        var width: CGFloat
        func body(content: Content) -> some View {
            content.frame(width: width)
        }
    }
}

private extension String {
    var doubleValue: Double? {
        Double(self.trimmingCharacters(in: .whitespacesAndNewlines))
    }
}

extension OnboardingData {
    var genderImage: Image {
        switch gender {
        case .male:   return AppImages.Goal.maleGoal
        case .female: return AppImages.Goal.femaleGoal
        case .other, .none: return Image(systemName: "gear")
        }
    }
    var weightUnitLabel: String { unit == .imperial ? "lbs" : "kg" }
}


#Preview {
    OnboardingFlow {
        print("Onboarding finished")
    }
}
