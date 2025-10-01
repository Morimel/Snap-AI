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
                .task {
                                    #if DEBUG
                                    // 1 «день» = 10 секунд → триал 70 секунд, «месяц» ~5 минут
                                    paywall.debug_setSecondsPerDay(10)
                                    #endif
                                }
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)   /// возврат из Google
                }
                .task {
                    /// настройка Google
                    GIDSignIn.sharedInstance.configuration = GIDConfiguration(
                        clientID: "476536036663-4oq1juohef5l7o9knhb5vhlu11nojucn.apps.googleusercontent.com"
                    )
                }
                .task {
                    if TokenStore.load() != nil {
                        UserDefaults.standard.set(true, forKey: AuthFlags.isRegistered)
                    }
                    CurrentUser.ensureIdFromJWTIfNeeded()
                }
        }
    }
}

private struct RootContainer: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false

    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var paywall: PaywallCenter

    @State private var showSplash = true
    @State private var paywallPresented = false
    @State private var showPaywall = false
    @State private var path = NavigationPath()

    @AppStorage("isSubscribed") private var isSubscribed = false
    @AppStorage("trialStartTS") private var trialStartTS: Double = 0
    private let trialLength: TimeInterval = 7 * 24 * 3600

    @StateObject private var vm: OnboardingViewModel

    init() {
        _vm = StateObject(
            wrappedValue: OnboardingViewModel(
                repository: BackendOnboardingRepository(),
                onFinished: {
                    UserDefaults.standard.set(true, forKey: "hasOnboarded")
                }
            )
        )
    }

    /// paywall-хелперы
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
        // TODO: реальная покупка
        isSubscribed = true
        showPaywall = false
    }

    var body: some View {
        ZStack {
            if hasOnboarded {
                NavigationStack {
                    MainScreen(vm: vm)
                }
            } else {
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
        .fullScreenCover(isPresented: $paywallPresented) {
            PayWallScreen(
                mode: paywall.mode,
                onStartTrial: { paywall.startTrialAndClose() },          // ⬅️ новое имя
                onProceed:    { product in paywall.payStub(for: product) } // ⬅️ передаём продукт
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
            refreshPaywallPresentation()
        }
    }
}

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
