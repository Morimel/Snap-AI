//
//  RateStep.swift
//  SnapAI
//
//  Created by Isa Melsov on 23/9/25.
//

import SwiftUI
import StoreKit

//MARK: - RateStep
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
