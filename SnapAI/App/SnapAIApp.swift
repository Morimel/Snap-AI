//
//  SnapAIApp.swift
//  SnapAI
//
//  Created by Isa Melsov on 15/9/25.
//

import SwiftUI
import GoogleSignIn

@main
struct SnapAIApp: App {
    @StateObject private var paywall = PaywallCenter()

    var body: some Scene {
        WindowGroup {
            RootContainer()
                .environmentObject(paywall)
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)   // возврат из Google
                }
                .task {
                    // настройка Google
                    GIDSignIn.sharedInstance.configuration = GIDConfiguration(
                        clientID: "476536036663-4oq1juohef5l7o9knhb5vhlu11nojucn.apps.googleusercontent.com"
                    )
                }
                .task {
                    // если уже есть токены — пометим как зарегистрирован
                    if TokenStore.load() != nil {
                        UserDefaults.standard.set(true, forKey: AuthFlags.isRegistered)
                    }
                    // подстрахуем: вытащим user_id из access JWT (для SettingsView)
                    CurrentUser.ensureIdFromJWTIfNeeded()
                }
        }
    }
}

private struct RootContainer: View {
    // онбординг завершён?
    @AppStorage("hasOnboarded") private var hasOnboarded = false

    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var paywall: PaywallCenter

    @State private var showSplash = true
    @State private var paywallPresented = false
    @State private var showPaywall = false
    @State private var path = NavigationPath()

    // Подписка/триал
    @AppStorage("isSubscribed") private var isSubscribed = false
    @AppStorage("trialStartTS") private var trialStartTS: Double = 0
    private let trialLength: TimeInterval = 7 * 24 * 3600

    // ВАЖНО: создаём VM с BackendOnboardingRepository
    @StateObject private var vm: OnboardingViewModel

    init() {
        _vm = StateObject(
            wrappedValue: OnboardingViewModel(
                repository: BackendOnboardingRepository(),
                onFinished: {
                    // флипнем онбординг-флаг через UserDefaults (чтобы не заморачиваться со self в init)
                    UserDefaults.standard.set(true, forKey: "hasOnboarded")
                }
            )
        )
    }

    // paywall-хелперы
    private var isTrialActive: Bool {
        guard trialStartTS > 0 else { return false }
        return Date().timeIntervalSince1970 - trialStartTS < trialLength
    }
    private var isTrialExpired: Bool { trialStartTS > 0 && !isTrialActive }

    private func refreshPaywallPresentation() {
        showPaywall = (!isSubscribed && (trialStartTS == 0 || isTrialExpired))
    }
    private func startTrialAndClose() {
        if trialStartTS == 0 { trialStartTS = Date().timeIntervalSince1970 }
        showPaywall = false
    }
    private func proceedPurchase() {
        // TODO: реальная покупка; пока — мокаем
        isSubscribed = true
        showPaywall = false
    }

    var body: some View {
        ZStack {
            if hasOnboarded {
                NavigationStack {
                    // Если MainScreen ждёт vm — передаём ту же VM
                    MainScreen(vm: vm)
                }
            } else {
                // Передаём эту же VM в онбординг
                OnboardingFlow(vm: vm, onFinish: {
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
        // показ paywall-а централизованно
        .fullScreenCover(isPresented: $paywallPresented) {
            PayWallScreen(
                mode: paywall.mode,
                onStartTrial: { paywall.startGraceMinuteAndClose() },
                onProceed:    { paywall.payStub() }
            )
        }
        .onReceive(paywall.$isShowing.removeDuplicates()) { paywallPresented = $0 }
        .onChange(of: paywallPresented) { paywall.isShowing = $0 }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active { paywall.onBecameActive() }
        }
        .task {
            // splash
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            withAnimation(.easeOut(duration: 0.35)) { showSplash = false }
        }
        .task {
            // если хочешь автологику показа paywall
            refreshPaywallPresentation()
        }
    }
}

// Маршрутизатор для локального просмотра плана (не обязателен, но оставлю)
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
