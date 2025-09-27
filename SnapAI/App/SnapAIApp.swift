//
//  SnapAIApp.swift
//  SnapAI
//
//  Created by Isa Melsov on 15/9/25.
//

import SwiftUI

@main
struct SnapAIApp: App {
    @StateObject private var paywall = PaywallCenter()
    var body: some Scene {
        WindowGroup {
            RootContainer()
                .environmentObject(paywall)
        }
    }
}

private struct RootContainer: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @EnvironmentObject private var paywall: PaywallCenter
    @State private var paywallPresented = false

    // Подписка/триал
    @AppStorage("isSubscribed") private var isSubscribed = false
    @AppStorage("trialStartTS") private var trialStartTS: Double = 0
    private let trialLength: TimeInterval = 7 * 24 * 3600

    @State private var showSplash = true
    @State private var showPaywall = false
    @State private var path = NavigationPath()
    @Environment(\.scenePhase) private var scenePhase

    @StateObject private var obVM =
        OnboardingViewModel(repository: LocalRepository(), onFinished: {})

    private var isTrialActive: Bool {
        guard trialStartTS > 0 else { return false }
        return Date().timeIntervalSince1970 - trialStartTS < trialLength
    }
    private var isTrialExpired: Bool {
        trialStartTS > 0 && !isTrialActive
    }

    private func refreshPaywallPresentation() {
        // Показываем paywall если нет подписки и (триал не начинался ИЛИ триал закончился)
        showPaywall = (!isSubscribed && (trialStartTS == 0 || isTrialExpired))
    }

    private func startTrialAndClose() {
        if trialStartTS == 0 { trialStartTS = Date().timeIntervalSince1970 }
        showPaywall = false   // попадём в MainScreen
    }

    private func proceedPurchase() {
        // TODO: интеграция StoreKit. Пока — мокаем успех покупки:
        isSubscribed = true
        showPaywall = false
    }

    var body: some View {
                
        ZStack {
            if hasOnboarded {
                NavigationStack {
                    MainScreen(vm: obVM)
                }
            } else {
                OnboardingFlow(vm: obVM, onFinish: {
                    hasOnboarded = true
                })
            }

            if showSplash {
                SplashScreen()
                    .transition(.opacity)
                    .zIndex(1)
                    .statusBarHidden(true)
            }
        }
        .fullScreenCover(isPresented: $paywallPresented) {
                    PayWallScreen(
                        mode: paywall.mode,
                        onStartTrial: { paywall.startGraceMinuteAndClose() }, // ✕ / Start for free
                        onProceed:    { paywall.payStub() }                   // Pay (заглушка)
                    )
                }
        .onReceive(paywall.$isShowing.removeDuplicates()) { paywallPresented = $0 }
                .onChange(of: paywallPresented) { paywall.isShowing = $0 }
        .onChange(of: scenePhase, perform: { newPhase in
            if newPhase == .active { paywall.onBecameActive() }
        })
        .task {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            withAnimation(.easeOut(duration: 0.35)) { showSplash = false }
        }
    }
}

//MARK: - PlanHostView.swift
struct PlanHostView: View {
    @State private var plan: PersonalPlan?
    private let repo = LocalRepository()
    var body: some View {
        Group {
            if let plan { PlanScreen(plan: plan) }
            else {
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Готовим ваш план…").foregroundColor(.secondary)
                    Button("Обновить") { load() }
                }.padding()
            }
        }
        .navigationTitle("Твой план")
        .onAppear(perform: load)
    }
    private func load() { plan = repo.fetchSavedPlan() }
}

