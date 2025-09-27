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
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @ObservedObject var vm: OnboardingViewModel
    @Binding var path: NavigationPath          // ← добавили
    
    @State private var currentRating = 0
    @State private var showFeedbackForm = false
    @State private var showSubmitting = false
    @State private var showPlan = false           // 👈 добавили
    @State private var showError = false          // 👈 добавили
    @State private var errorMsg = ""              // 👈 добавили
    @State private var pendingReviewLaunch = false  // ← флаг ожидания возврата из App Store
    
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase  // ← чтобы ловить возврат из App Store
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
            default: break
            }
        }
        // Возврат из App Store → стартуем сабмит
        .onChange(of: scenePhase) { phase in
            if phase == .active, pendingReviewLaunch {
                pendingReviewLaunch = false
                startSubmitting()
            }
        }
        // Если вдруг флаг онбординга переключился — закроем покрытия
        .onChange(of: hasOnboarded) { new in
            if new {
                showPlan = false
                showSubmitting = false
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
                    ReviewCard(
                        avatarName: "review1",
                        author: "Michael Brooks",
                        text: "I was shocked! I just snapped a\nphoto of my food, and Snap AI\ninstantly counted the calories!",
                        rating: 5
                    )
                    ReviewCard(
                        avatarName: "review2",
                        author: "Sophia Carter",
                        text: "I always thought counting\ncalories was hard. But here, I\njust snapped a photo — and it\nwas all done!",
                        rating: 5
                    )
                    ReviewCard(
                        avatarName: "review3",
                        author: "Daniel Reed",
                        text: "A photo of food and instantly\nthe calories? I had no idea\ntechnology could be this\nconvenient!",
                        rating: 4
                    )
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
                Button {
                    startSubmitting()
                } label: {
                    BackButton()
                }
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
                onSend: { _ in startSubmitting() },   // ← сюда
                onSkip: { startSubmitting() }         // ← и сюда
            )
        }
    }
    
    private func requestStoreReview() {
        if let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene }).first {
            SKStoreReviewController.requestReview(in: scene)
        }
    }
    
    private func startSubmitting() {
        guard !showSubmitting else { return }
        showSubmitting = true
        vm.phase = .submitting
    }
    
    
    private func rateAndProceed() {
        if currentRating >= 4 {
            pendingReviewLaunch = true
            if let url = URL(string: "https://apps.apple.com/app/id\(appID)?action=write-review") {
                openURL(url)
            } else {
                requestStoreReview()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { startSubmitting() }
            }
        } else {
            showFeedbackForm = true
        }
    }
}

#Preview {
    NavigationStack {
        RateStep(
            vm: OnboardingViewModel(repository: LocalRepository(), onFinished: {}),
            path: .constant(NavigationPath())
        )
    }
}

