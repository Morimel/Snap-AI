//
//  LoginView.swift
//  SnapAI
//
//  Created by Isa Melsov on 24/9/25.
//

import SwiftUI

struct LoginView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var vm: OnboardingViewModel
    @EnvironmentObject private var paywall: PaywallCenter
    var onSuccess: () -> Void                 

    @State private var focalYOffset: CGFloat = 0

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
                        Text("Log in")
                            .font(.system(size: 36, weight: .regular))
                            .foregroundColor(AppColors.primary)
                            .frame(maxWidth: .infinity, minHeight: 56)
                            .overlay(alignment: .leading) {
                                CircleIconButton { dismiss() }
                                    .frame(width: 44, height: 44)
                            }
                            .padding(.horizontal, 16)

                    AuthScreenLogin(onContinue: {
                        if paywall.hasPayed {
                            onSuccess()
                        } else {
                            paywall.presentLocked()
                        }

                            })
                            .onChange(of: paywall.hasPayed) { paid in
                                if paid { onSuccess() }
                            }
                }
                .navigationBarBackButtonHidden(true)
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    UnevenRoundedRectangle(cornerRadii: .init(topLeading: 28, topTrailing: 28))
                        .fill(AppColors.background)
                        .ignoresSafeArea(edges: .bottom)
                )
                .shadow(color: .black.opacity(0.08), radius: 12, y: -2)
            }
        }
        .hideKeyboardOnTap()
    }
}


struct PillFieldStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 16))
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, minHeight: 56)
            .foregroundStyle(AppColors.primary)
            .background(AppColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.2), radius: 8, y: 2)
    }
}
extension View { func pillFieldStyle() -> some View { modifier(PillFieldStyle()) } }



// MARK: - Reusable input
struct LabeledInput: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false

    var isInvalid: Bool = false
    var errorText: String? = nil

    var focused: FocusState<Bool>.Binding? = nil

    @State private var reveal = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.callout.weight(.semibold))
                .foregroundStyle(.secondary)

            ZStack {
                Group {
                    if isSecure && !reveal {
                        SecureField("",
                                    text: $text,
                                    prompt: styledPlaceholder(placeholder, color: AppColors.primary.opacity(0.35)))
                            .textContentType(.password)
                            .applyFocus(focused)
                            .foregroundColor(isInvalid ? .red : AppColors.text)
                            .pillFieldStyle()
                    } else {
                        TextField("",
                                  text: $text,
                                  prompt: styledPlaceholder(placeholder, color: AppColors.primary.opacity(0.35)))
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .keyboardType(isSecure ? .default : .emailAddress)
                            .textContentType(isSecure ? .password : .emailAddress)
                            .applyFocus(focused)
                            .foregroundColor(isInvalid ? .red : AppColors.primary)
                            .pillFieldStyle()
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(isInvalid ? Color.red : Color.clear, lineWidth: 1.5)
                )

                .overlay(alignment: .trailing) {
                    if isSecure {
                        Button {
                            reveal.toggle()
                        } label: {
                            Image(systemName: reveal ? "eye.slash" : "eye")
                                .foregroundColor(AppColors.primary)
                                .font(.system(size: 16, weight: .medium))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                        }
                        .buttonStyle(.plain)
                        .tint(isInvalid ? .red : AppColors.primary)
                        .accessibilityLabel(reveal ? "Hide password" : "Show password")
                    }
                }
            }

            if let errorText, isInvalid {
                Text(errorText)
                    .font(.footnote)
                    .foregroundColor(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

private extension View {
    func applyFocus(_ binding: FocusState<Bool>.Binding?) -> some View {
        if let b = binding {
            return AnyView(self.focused(b))
        } else {
            return AnyView(self)
        }
    }
}

// MARK: - Social button
struct SocialButton: View {
    let title: String
    let systemImage: String
    var background: Color = .black
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.system(size: 18, weight: .semibold))
                Text(title)
                    .font(.headline)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 56)
            .contentShape(Rectangle())
        }
        .background(background)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

// MARK: - Screen
struct AuthScreenLogin: View {
    var onContinue: () -> Void
    @State private var email = ""
    @State private var password = ""
    
    @FocusState private var emailFocused: Bool
        @FocusState private var passwordFocused: Bool
        @State private var didAttempt = false

        @State private var isLoading = false
        @State private var formError: String?
    @EnvironmentObject private var router: OnboardingRouter


        @AppStorage(AuthFlags.isRegistered) private var isRegistered = false
    
    private var emailTrimmed: String { email.trimmingCharacters(in: .whitespacesAndNewlines) }

    private func isValidEmail(_ s: String) -> Bool {
           let pattern = #"^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$"#
           return NSPredicate(format: "SELF MATCHES[c] %@", pattern).evaluate(with: s)
       }
    
    private var isEmailValid: Bool {
            !emailTrimmed.isEmpty && isValidEmail(emailTrimmed)
        }
        private var isPasswordValid: Bool {
            !password.isEmpty
        }

        private var showEmailError: Bool {
            !emailTrimmed.isEmpty && !isValidEmail(emailTrimmed) && (didAttempt || !emailFocused)
        }
        private var showPasswordError: Bool {
            !password.isEmpty && (password.count < 1) && (didAttempt || !passwordFocused)
        }

        private var isFormValid: Bool { isEmailValid && isPasswordValid }
    
    private func login() {
            didAttempt = true
            guard isFormValid, !isLoading else { return }

            isLoading = true
            formError = nil

            Task {
                do {
                    let pair = try await AuthAPI.shared.token(email: emailTrimmed, password: password)
                    TokenStore.save(.init(access: pair.access, refresh: pair.refresh))
                    
                    if let u = pair.user {
                                    UserStore.save(id: u.id, email: u.email)
                                } else {
                                    if let id = JWTTools.userId(from: pair.access) {
                                        UserStore.save(id: id, email: JWTTools.email(from: pair.access))
                                    }
                                }
                    isRegistered = true
                    await MainActor.run { onContinue() }
                } catch let APIError.validation(map) {
                    await MainActor.run {
                        formError = map.values.first?.first ?? "Invalid e-mail or password."
                        isLoading = false
                    }
                } catch APIError.http(_, let body) {
                    await MainActor.run {
                        formError = body?.isEmpty == false ? body : "Login failed. Try again."
                        isLoading = false
                    }
                } catch {
                    await MainActor.run {
                        formError = error.localizedDescription
                        isLoading = false
                    }
                }
            }
        }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            LabeledInput(
                label: "E-mail:",
                placeholder: "Your e-mail",
                text: $email,
                isInvalid: showEmailError,
                errorText: showEmailError ? "Invalid e-mail" : nil,
                focused: $emailFocused
            )
            LabeledInput(
                label: "Password:",
                placeholder: "Your password",
                text: $password,
                isSecure: true,
                isInvalid: showPasswordError,
                errorText: showPasswordError ? "Enter your password" : nil,
                focused: $passwordFocused
            )
            
            Button(action: login) {
                ZStack {
                    Text(isLoading ? "Signing in…" : "Continue")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 56)
                    if isLoading {
                        ProgressView().controlSize(.regular)
                    }
                }
            }
            .background(isFormValid ? AppColors.secondary : AppColors.secondary.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .padding(.top, 6)
            .disabled(!isFormValid || isLoading)
            .submitLabel(.go)
            .onSubmit { login() }
            
            HStack {
                Rectangle().fill(AppColors.text.opacity(0.12)).frame(height: 1)
                Text("or").font(.subheadline.weight(.semibold)).foregroundStyle(.secondary)
                Rectangle().fill(AppColors.text.opacity(0.12)).frame(height: 1)
            }
            .padding(.vertical, 6)
            
            SocialButton(title: "Continue with Apple", systemImage: "apple.logo") {
                signInWithApple(onAuthSuccess: onContinue)
            }
            SocialButton(title: "Continue with Google", systemImage: "g.circle.fill") {
                signInWithGoogle(onAuthSuccess: onContinue)
            }

        }
    }
}

#Preview {
    LoginView(vm: OnboardingViewModel(repository: LocalRepository(), onFinished: {}), onSuccess: { })
}
