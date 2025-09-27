//
//  OnboardingFlow.swift
//  SnapAI
//
//  Created by Isa Melsov on 23/9/25.
//
import SwiftUI

struct OnboardingFlow: View {
    @ObservedObject var vm: OnboardingViewModel
    @StateObject private var router = OnboardingRouter()
    var onFinish: (() -> Void)? = nil
    // Если после нового пароля хочешь сразу выйти в app:
    // @AppStorage("hasOnboarded") private var hasOnboarded = false
    
    var body: some View {
        NavigationStack(path: $router.path) {
            StartStep(vm: vm)
                .navigationDestination(for: OnbRoute.self) { route in
                    switch route {
                    case .start:    StartStep(vm: vm)
                    case .meeting:  MeetingScreen(vm: vm)
                    case .login:
                        LoginView(vm: vm, onSuccess: {
                            // (не обязательно, но можно подчистить путь)
                            router.popToRoot()
                            // сообщаем корню выйти в основное приложение
                            onFinish?()
                        })
                        .navigationBarBackButtonHidden(true)
                    case .register:
                        RegisterView(vm: vm) { email in
                            vm.data.email = email
                            router.push(.newPassword(email: email))   // 👈 передаём email
                        }
                    case .emailOTP(let email, let sessionId, let password):
                            EmailConfirmationView(
                                vm: vm,
                                email: email,
                                sessionId: sessionId,
                                passwordForVerify: password
                            )
                    case .newPassword(let email):
                            NewPasswordView(vm: vm, email: email)  // ← без колбэка
                            .navigationBarBackButtonHidden(true)
                    case .gender:
                        GenderStep(vm: vm)
                            .navigationBarBackButtonHidden(true) // чтобы нельзя было вернуться назад
                    }
                }
        }
        .environmentObject(router)
    }
}

enum OnbRoute: Hashable {
    case start
    case meeting
    case login
    case register
    case emailOTP(email: String, sessionId: String, password: String)
    case newPassword(email: String)
    case gender
}


final class OnboardingRouter: ObservableObject {
    @Published var path: [OnbRoute] = []
    func push(_ r: OnbRoute) { path.append(r) }
    func pop(_ n: Int = 1) { path.removeLast(min(n, path.count)) }
    func popToRoot() { path.removeAll() }
    func replace(with stack: [OnbRoute]) { path = stack }
}
