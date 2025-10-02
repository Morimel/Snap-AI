//
//  RegisterView.swift
//  SnapAI
//
//  Created by Isa Melsov on 24/9/25.
//

import SwiftUI
import AuthenticationServices

struct RegisterView: View {
    
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var vm: OnboardingViewModel
    @State private var focalYOffset: CGFloat = 0
    var onContinue: (String) -> Void
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                AppImages.OtherImages.food1
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                    .offset(y: focalYOffset)
                    .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    
                    Text("Create account")
                        .font(.system(size: 36, weight: .regular))
                        .foregroundColor(AppColors.primary)
                        .frame(maxWidth: .infinity, minHeight: 56)
                        .overlay(alignment: .leading) {
                            CircleIconButton { dismiss() }
                                .frame(width: 44, height: 44)
                        }
                        .padding(.horizontal, 16)
                    
                    AuthScreenRegister(onContinue: onContinue)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    UnevenRoundedRectangle(cornerRadii: .init(topLeading: 28, topTrailing: 28))
                        .fill(AppColors.background)
                        .ignoresSafeArea(edges: .bottom)   // фон уходит под home indicator
                )
                .shadow(color: .black.opacity(0.08), radius: 12, y: -2)
            }
        }
        .hideKeyboardOnTap()
        .navigationBarBackButtonHidden(true)
    }
}

// MARK: - Screen
struct AuthScreenRegister: View {
    var onContinue: (String) -> Void
    @State private var email = ""
    @FocusState private var emailFocused: Bool
    @State private var didAttemptSubmit = false
    @State private var pendingNonce: String?
    @EnvironmentObject private var router: OnboardingRouter
    
    @State private var isBusy = false
    @State private var alertMessage: String?
    
    private var emailTrimmed: String {
        email.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// простая проверка e-mail (RFC-лайт)
    private func isValidEmail(_ s: String) -> Bool {
        let pattern = #"^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$"#
        return NSPredicate(format: "SELF MATCHES[c] %@", pattern).evaluate(with: s)
    }
    
    private var emailError: String? {
        let s = emailTrimmed
        guard !s.isEmpty else { return nil }
        return isValidEmail(s) ? nil : "Invalid e-mail"
    }
    
    private var isFormValid: Bool {
        let s = emailTrimmed
        return !s.isEmpty && isValidEmail(s)
    }
    
    private var shouldShowError: Bool {
        let s = emailTrimmed
        guard !s.isEmpty else { return false }
        let invalid = !isValidEmail(s)
        return invalid && (didAttemptSubmit || !emailFocused)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            LabeledInput(label: "E-mail:",
                         placeholder: "Your e-mail",
                         text: $email,
                         isInvalid: shouldShowError,
                         errorText: emailError,
                         focused: $emailFocused
            )
            .submitLabel(.continue)
            .onSubmit {
                didAttemptSubmit = true
                if isFormValid { onContinue(emailTrimmed) }
            }
            
            Button {
                didAttemptSubmit = true
                if isFormValid { onContinue(emailTrimmed) }
            } label: {
                Text("Continue")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 56)
            }
            .background(AppColors.secondary)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .padding(.top, 6)
            
            HStack {
                Rectangle().fill(AppColors.text.opacity(0.12)).frame(height: 1)
                Text("or").font(.subheadline.weight(.semibold)).foregroundStyle(.secondary)
                Rectangle().fill(AppColors.text.opacity(0.12)).frame(height: 1)
            }
            .padding(.vertical, 6)
            
            SocialButton(title: "Continue with Apple", systemImage: "apple.logo") {
                guard !isBusy else { return }
                isBusy = true
                signInWithApple {
                    // Успех
                    CurrentUser.ensureIdFromJWTIfNeeded()
                    router.replace(with: [.gender])
                    isBusy = false
                }
            }
            .disabled(isBusy)
            .opacity(isBusy ? 0.8 : 1)
            
            SocialButton(title: "Continue with Google", systemImage: "g.circle.fill") {
                signInWithGoogleAndRoute(router: router)
            }
            .disabled(isBusy)
            .opacity(isBusy ? 0.6 : 1)
        }
        .alert(item: Binding.constant(alertMessage.map { AlertItem(message: $0) })) { a in
                    Alert(title: Text("Error"), message: Text(a.message), dismissButton: .default(Text("OK")))
                }
    }
}




private struct AlertItem: Identifiable { let id = UUID(); let message: String }


#Preview {
    RegisterView(vm: OnboardingViewModel(repository: LocalRepository(), onFinished: {}), onContinue: { _ in })
}

struct SignInWithAppleButtonView: UIViewRepresentable {
    var type: ASAuthorizationAppleIDButton.ButtonType = .continue
    var style: ASAuthorizationAppleIDButton.Style
    var cornerRadius: CGFloat = 18
    var action: () -> Void

    func makeUIView(context: Context) -> ASAuthorizationAppleIDButton {
        let button = ASAuthorizationAppleIDButton(type: type, style: style)
        button.cornerRadius = cornerRadius
        button.addTarget(context.coordinator, action: #selector(Coordinator.didTap), for: .touchUpInside)
        return button
    }

    func updateUIView(_ uiView: ASAuthorizationAppleIDButton, context: Context) { }

    func makeCoordinator() -> Coordinator { Coordinator(action: action) }

    final class Coordinator: NSObject {
        let action: () -> Void
        init(action: @escaping () -> Void) { self.action = action }
        @objc func didTap() { action() }
    }
}
