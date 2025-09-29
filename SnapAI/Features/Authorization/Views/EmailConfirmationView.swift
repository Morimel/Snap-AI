//
//  OTPView.swift
//  SnapAI
//
//  Created by Isa Melsov on 24/9/25.
//

import SwiftUI
import Combine
import UIKit   // для haptic

// MARK: - Keyboard listener (минимальный)
final class KeyboardObserver: ObservableObject {
    @Published var height: CGFloat = 0
    
    private var bag = Set<AnyCancellable>()
    
    init() {
        let willChange = NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)
        let willHide   = NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
        
        willChange.merge(with: willHide)
            .receive(on: RunLoop.main)
            .sink { [weak self] note in
                guard let self else { return }
                let end = (note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect) ?? .zero
                // если клавы нет — высота 0
                // если есть — берём её высоту
                if end.minY >= UIScreen.main.bounds.height { self.height = 0 }
                else { self.height = end.height }
            }
            .store(in: &bag)
    }
}

// MARK: - OTP ячейка
private struct OTPDigit: View {
    let char: String
    var body: some View {
        Text(char.isEmpty ? "•" : char)
            .font(.system(size: 36, weight: .semibold))
            .frame(width: 36, height: 44, alignment: .center)
            .monospaced()
            .foregroundStyle(AppColors.text)
            .animation(.easeOut(duration: 0.15), value: char)
    }
}

// Геометрический эффект "shake"
struct ShakeEffect: GeometryEffect {
    var amount: CGFloat = 12
    var shakesPerUnit: CGFloat = 3
    var animatableData: CGFloat
    
    func effectValue(size: CGSize) -> ProjectionTransform {
        let translation = amount * sin(animatableData * .pi * shakesPerUnit)
        return ProjectionTransform(CGAffineTransform(translationX: translation, y: 0))
    }
}

// MARK: - Экран подтверждения
struct EmailConfirmationView: View {
    @ObservedObject var vm: OnboardingViewModel
    @AppStorage(AuthFlags.isRegistered) private var isRegistered = false
    
    let email: String
    let sessionId: String
    let passwordForVerify: String
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var router: OnboardingRouter   // ← пушим .newPassword отсюда
    @StateObject private var kb = KeyboardObserver()
    
    // 4 ячейки (визуал)
    @State private var d0 = ""
    @State private var d1 = ""
    @State private var d2 = ""
    @State private var d3 = ""
    
    // скрытое поле + фокус
    @State private var otpText = ""
    @FocusState private var otpFocused: Bool
    
    let slot: CGFloat = 44
    
    // shake-триггер
    @State private var shakePhase: CGFloat = 0
    @State private var didRoute = false
    @State private var isLoading = false
    @State private var errorText: String?
    
    // resend-cooldown
    @State private var cooldownRemaining: Int = 0      // в секундах
    @State private var cooldownTimer: Timer?
    @State private var isResending = false
    
    
    private var isResendDisabled: Bool { isResending || cooldownRemaining > 0 }
    private var resendTitle: String {
        guard cooldownRemaining > 0 else { return "Resend code" }
        let m = cooldownRemaining / 60
        let s = cooldownRemaining % 60
        return String(format: "Resend code (%d:%02d)", m, s)
    }
    
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                AppImages.OtherImages.food1
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                    .overlay(Color.black.opacity(0.25))
                    .ignoresSafeArea()
                
                VStack(alignment: .leading, spacing: 20) {
                    
                    HStack(spacing: 0) {
                        // слева — кнопка
                        CircleIconButton { dismiss() }
                            .frame(width: slot, height: slot)
                        
                        Spacer(minLength: 0)
                        
                        // справа — пустой балансир той же ширины
                        Color.clear.frame(width: slot, height: slot)
                    }
                    .overlay {                                   // заголовок поверх, центрирован
                        Text("E-mail Confirmation")
                            .font(.system(size: 28, weight: .regular))
                            .foregroundColor(AppColors.primary)
                            .lineLimit(1)
                            .truncationMode(.middle)               // или .middle, если хочешь
                            .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 56)
                    
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Confirmation code was sent to:")
                            .font(.callout.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text(email)
                            .font(.callout)
                            .foregroundStyle(AppColors.text)
                    }
                    
                    // Ячейки кода + shake
                    HStack(spacing: 16) {
                        OTPDigit(char: d0)
                        OTPDigit(char: d1)
                        OTPDigit(char: d2)
                        OTPDigit(char: d3)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { otpFocused = true }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 6)
                    .modifier(ShakeEffect(animatableData: shakePhase)) // ← тряска
                    
                    // Скрытое поле
                    TextField("", text: Binding(
                        get: { otpText },
                        set: { new in
                            let filtered = new.filter(\.isNumber).prefix(4)
                            otpText = String(filtered)
                            
                            // разбрасываем по визуальным ячейкам
                            let chars = Array(otpText)
                            d0 = chars.indices.contains(0) ? String(chars[0]) : ""
                            d1 = chars.indices.contains(1) ? String(chars[1]) : ""
                            d2 = chars.indices.contains(2) ? String(chars[2]) : ""
                            d3 = chars.indices.contains(3) ? String(chars[3]) : ""
                            
                            if otpText.count == 4 {
                                otpFocused = false
                                handleFilledCode()
                            }
                        }
                    ))
                    .keyboardType(.numberPad)
                    .textContentType(.oneTimeCode)    // оставим так, чтобы не плодить логи
                    .focused($otpFocused)
                    .frame(width: 1, height: 1)
                    .opacity(0.05)
                    .accessibilityHidden(true)
                    
                    Button {
                        Task { await resend() }
                    } label: {
                        Text(resendTitle)
                            .font(.headline)
                            .frame(maxWidth: .infinity, minHeight: 52)
                            .foregroundStyle(AppColors.text)
                            .background(AppColors.surface)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16).stroke(AppColors.text.opacity(0.10), lineWidth: 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: .black.opacity(0.06), radius: 4)
                    }
                    .padding(.top, 4)
                    .disabled(isResendDisabled)
                    .opacity(isResendDisabled ? 0.6 : 1)
                }
                .padding(.bottom, 12)
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 28)
                        .fill(AppColors.background)
                        .ignoresSafeArea(edges: .bottom)
                )
                .shadow(color: .black.opacity(0.08), radius: 12, y: -2)
                .offset(y: -lift(geo: geo))
                .animation(.spring(response: 0.28, dampingFraction: 0.9), value: kb.height)
                .ignoresSafeArea(.keyboard, edges: .bottom)
                .compositingGroup()
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .onAppear { DispatchQueue.main.async { otpFocused = true } }
            .onDisappear { didRoute = false }
            .onDisappear {
                didRoute = false
                cooldownTimer?.invalidate()
                cooldownTimer = nil
            }
        }
        .hideKeyboardOnTap()
        .navigationBarBackButtonHidden(true)
    }
    
    // MARK: - Helpers
    
    private func lift(geo: GeometryProxy) -> CGFloat {
        let k = kb.height
        let safe = geo.safeAreaInsets.bottom
        return max(0, k - safe + 2)
    }
    
    private func handleFilledCode() {
        guard !isLoading, !didRoute else { return }
        isLoading = true                // ← ставим флаг сразу
        Task { await verify() }
    }

    
    @MainActor
    private func verify() async {
        errorText = nil
        defer { isLoading = false }     // сбросим только если была ошибка

        do {
            let pair = try await AuthAPI.shared.verify(
                sessionId: sessionId,
                otp: otpText,
                password: passwordForVerify
            )
            TokenStore.save(.init(access: pair.access, refresh: pair.refresh))
            UserStore.save(id: pair.user?.id, email: pair.user?.email)
            isRegistered = true
            // TODO: сохранить pair.access / pair.refresh в Keychain
            guard !didRoute else { return }
            didRoute = true
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            router.replace(with: [.gender])
        } catch APIError.validation(let map) {
            errorText = map.values.first?.first ?? "Неверный код."
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            withAnimation(.default) { shakePhase += 1 }
            clearCodeAndRefocus()
        } catch APIError.http(_, let body) {
            errorText = body ?? "Ошибка проверки. Попробуйте ещё раз."
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            withAnimation(.default) { shakePhase += 1 }
            clearCodeAndRefocus()
        } catch {
            errorText = "Ошибка проверки. Попробуйте ещё раз."
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            withAnimation(.default) { shakePhase += 1 }
            clearCodeAndRefocus()
        }
    }

    private func clearCodeAndRefocus() {
        otpText = ""
        d0 = ""; d1 = ""; d2 = ""; d3 = ""
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            otpFocused = true
        }
    }
    
    // MARK: - Resend + cooldown
    @MainActor
    private func resend() async {
        guard !isResendDisabled else { return }
        isResending = true
        startCooldown(120) // 2 минуты
        defer { isResending = false }
        do {
            try await AuthAPI.shared.resend(sessionId: sessionId)
        } catch APIError.http(let code, let body) {
            print("RESEND FAIL \(code): \(body ?? "")")
        } catch {
            print("RESEND FAIL: \(error)")
        }
    }
    
    @MainActor
    private func startCooldown(_ seconds: Int) {
        cooldownTimer?.invalidate()
        cooldownRemaining = seconds
        let t = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if cooldownRemaining > 0 { cooldownRemaining -= 1 }
            if cooldownRemaining == 0 {
                cooldownTimer?.invalidate()
                cooldownTimer = nil
            }
        }
        cooldownTimer = t
        RunLoop.main.add(t, forMode: .common)
    }
}


#Preview {
    NavigationStack {
        EmailConfirmationView(
            vm: OnboardingViewModel(repository: LocalRepository(), onFinished: {}),
            email: "preview@example.com",
            sessionId: "preview-session",
            passwordForVerify: "PreviewPass1"
        )
    }
}
