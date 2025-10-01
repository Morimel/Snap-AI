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
    @EnvironmentObject private var router: OnboardingRouter
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @ObservedObject var vm: OnboardingViewModel

    @State private var currentRating = 0
    @State private var showFeedbackForm = false
    @State private var showSubmitting = false
    @State private var showError = false
    @State private var errorMsg = ""
    @State private var pendingReviewLaunch = false

    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase
    private let appID = "1234567890" // TODO: реальный

    var body: some View {
        ZStack { content }
            .fullScreenCover(isPresented: $showSubmitting) {
                SubmittingOverlay(
                    title: "Creating your personalized meal\nand workout plan",
                    subtitle: "Analyzing your responses...",
                    progress: $vm.progress,
                    onCancel: nil
                )
                .task {
                    do {
                        await vm.finish()

                        guard let plan = vm.repository.fetchSavedPlan() ?? vm.personalPlan else {
                            throw NSError(domain: "plan", code: -1, userInfo: [NSLocalizedDescriptionKey: "Plan is empty"])
                        }

                        let caption = vm.data.goalCaption()

                        await MainActor.run { showSubmitting = false }
                        try? await Task.sleep(nanoseconds: 250_000_000)
                        await MainActor.run { router.push(.plan(plan, caption)) }
                    } catch {
                        await MainActor.run {
                            showSubmitting = false
                            errorMsg = error.localizedDescription
                            showError = true
                        }
                    }
                }

            }
            .onChange(of: scenePhase) { phase in
                if phase == .active, pendingReviewLaunch {
                    pendingReviewLaunch = false
                    startSubmitting()
                }
            }
            .alert("Ошибка", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMsg)
            }
    }

    // MARK: - Контент
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
                Button { startSubmitting() } label: { BackButton() }
            }
            ToolbarItem(placement: .principal) {
                Text("Rate Us")
                    .font(.system(size: 24, weight: .regular))
                    .foregroundStyle(AppColors.primary)
            }
        }
        .sheet(isPresented: $showFeedbackForm) {
            FeedbackSheet(
                rating: currentRating,
                onSend: { text in
                    // 1) Сразу переходим к сабмиту UX
                    startSubmitting()
                    // 2) Отправляем отзыв асинхронно, не блокируя переход
                    Task.detached {
                        _ = try? await AuthAPI.shared.createRating(stars: currentRating, comment: text, sentToStore: false)
                    }
                },
                onSkip: {
                    // 1) Сразу переходим
                    startSubmitting()
                    // 2) Отправляем «оценку без текста» в фоне
                    Task {
                        _ = try? await AuthAPI.shared.createRating(
                            stars: currentRating,
                            comment: nil,
                            sentToStore: false
                        )
                    }
                }
            )
        }

    }

    // MARK: - Хелперы
    private func requestStoreReview() {
        if let scene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first {
            SKStoreReviewController.requestReview(in: scene)
        }
    }

    private func startSubmitting() {
        guard !showSubmitting else { return }
        showSubmitting = true
        vm.phase = .submitting
    }

    private func rateAndProceed() {
        guard currentRating > 0 else { return }

        if currentRating >= 4 {
            // отправим оценку «в фоне»
            Task {
                try? await AuthAPI.shared.createRating(
                    stars: currentRating,
                    comment: nil,
                    sentToStore: true
                )
            }

            // пытаемся открыть App Store с формой отзыва
            if let url = URL(string: "https://apps.apple.com/app/id\(appID)?action=write-review") {
                openURL(url) { accepted in   // accepted: Bool
                    if accepted {
                        pendingReviewLaunch = true
                    } else {
                        pendingReviewLaunch = false
                        requestStoreReview()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { startSubmitting() }
                    }
                }
            } else {
                // URL не собрался — сразу fallback
                requestStoreReview()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { startSubmitting() }
            }

        } else {
            // рейтинг 1–3 → открываем форму фидбэка (там по onSend/onSkip уже вызывается startSubmitting())
            showFeedbackForm = true
        }
    }
}

#Preview {
    NavigationStack {
        RateStep(
            vm: OnboardingViewModel(repository: LocalRepository(), onFinished: {})
        )
        .environmentObject(OnboardingRouter())
    }
}
