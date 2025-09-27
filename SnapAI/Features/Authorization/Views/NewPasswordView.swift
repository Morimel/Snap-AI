//
//  NewPasswordView.swift
//  SnapAI
//
//  Created by Isa Melsov on 24/9/25.
//
import SwiftUI

struct NewPasswordView: View {
    @ObservedObject var vm: OnboardingViewModel
    let email: String                                 // 👈 добавили
    @EnvironmentObject private var router: OnboardingRouter
    @Environment(\.dismiss) private var dismiss
    @State private var focalYOffset: CGFloat = 0
    
    @State private var sessionId: String?
    @State private var goOTP = false
    @State private var lastPasswordForVerify = ""
    
    @State private var fieldErrors: [String: [String]] = [:]
    @State private var generalError: String?
    @State private var isLoading = false
    
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
                    Text("New password")
                        .font(.system(size: 36, weight: .regular))
                        .foregroundColor(AppColors.primary)
                        .padding(.leading, 8)
                    
                    NewPasswordRegister(
                        vm: vm,
                        onSave: { password in
                            Task { await start(email: email, password: password) }
                        },
                        fieldErrors: fieldErrors,
                        generalError: generalError,
                        isLoading: isLoading
                    )
                }
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
    
    @MainActor
    private func start(email: String, password: String) async {
        isLoading = true; fieldErrors = [:]; generalError = nil
        defer { isLoading = false }
        do {
            let resp = try await AuthAPI.shared.registerStart(email: email, password: password)
            lastPasswordForVerify = password

            // НЕ БЛОКИРУЕМ ПЕРЕХОД НА OTP
            router.push(.emailOTP(email: email, sessionId: resp.session_id, password: password))

            // опционально: мягкий лог (или можно показать тост уже на OTP)
            if resp.email_sent != true {
                print("⚠️ email_sent=false; пользователь сможет нажать Resend. hint:", resp.debug_hint ?? "—")
            }
        } catch APIError.validation(let map) {
            fieldErrors = map
        } catch APIError.http(let code, let body) {
            generalError = "Ошибка сервера (\(code)). \(body ?? "")"
        } catch APIError.decoding(let msg) {
            generalError = "Неверный формат ответа: \(msg)"
        } catch {
            generalError = "Не удалось отправить запрос. Проверьте интернет."
        }
    }
}

struct NewPasswordRegister: View {
    @ObservedObject var vm: OnboardingViewModel
    var onSave: (String) -> Void
    
    @State private var password = ""
    @State private var confirm  = ""
    
    var fieldErrors: [String: [String]] = [:]
        var generalError: String?
        var isLoading: Bool = false
    
    // MARK: - Validation
    private var passwordError: String? {
        guard !password.isEmpty else { return nil }
        if password.count < 8 { return "Пароль должен быть не короче 8 символов" }
        if password.range(of: "[A-Z]", options: .regularExpression) == nil {
            return "Пароль должен содержать хотя бы одну заглавную букву"
        }
        return nil
    }
    private var confirmError: String? {
        guard !confirm.isEmpty else { return nil }
        return (confirm == password) ? nil : "Пароли не совпадают"
    }
    private var isFormValid: Bool {
        passwordError == nil && confirmError == nil && !password.isEmpty && !confirm.isEmpty
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            
            if let errs = fieldErrors["email"] {
                            ForEach(errs, id: \.self) { Text($0).foregroundColor(.red).font(.footnote) }
                        }
            
            LabeledInput(
                            label: "Password:",
                            placeholder: "Enter password",
                            text: $password,
                            isSecure: true,
                            isInvalid: passwordError != nil || fieldErrors["password"] != nil,
                            errorText: passwordError ?? fieldErrors["password"]?.first
                        )
            
            LabeledInput(
                label: "Confirm password:",
                placeholder: "Repeat password",
                text: $confirm,
                isSecure: true,
                isInvalid: confirmError != nil,
                errorText: confirmError
            )
                        
            Button {
                guard isFormValid, !isLoading else { return }
                onSave(password)
            } label: {
                HStack {
                                    if isLoading { ProgressView() }
                                    Text("Sign Up")
                                        .font(.headline)
                                        .foregroundStyle(.white)
                                        .frame(maxWidth: .infinity, minHeight: 56)
                                }
            }
            .background(isFormValid ? AppColors.secondary : AppColors.secondary.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .padding(.top, 6)
            .disabled(!isFormValid || isLoading)
        }
    }
}



#Preview {
    NewPasswordView(
        vm: OnboardingViewModel(repository: LocalRepository(), onFinished: {}), email: "isaev@gmail.com",
    )
}
