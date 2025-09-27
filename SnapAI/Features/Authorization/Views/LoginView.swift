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
    var onSuccess: () -> Void                 // ← добавили

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
                            .frame(maxWidth: .infinity, minHeight: 56)   // высота строки
                            .overlay(alignment: .leading) {
                                CircleIconButton { dismiss() }           // кнопка слева
                                    .frame(width: 44, height: 44)        // удобный тач-таргет
                            }
                            .padding(.horizontal, 16)                    // общий отступ блока (опц.)

                    AuthScreenLogin(onContinue: {
                        if paywall.hasPayed {
                            onSuccess()
                        } else {
                            paywall.isShowing = true         // откроется locked, т.к. hasPayed == false
                        }

                            })
                    // если на paywall нажали Pay (заглушка), идём дальше
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

    // 🔻 Новые параметры для ошибок
    var isInvalid: Bool = false
    var errorText: String? = nil

    var focused: FocusState<Bool>.Binding? = nil

    // локальный стейт для «глаза»
    @State private var reveal = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.callout.weight(.semibold))
                .foregroundStyle(.secondary)

            ZStack {
                // Основное поле
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
                // Красный бордер при ошибке
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(isInvalid ? Color.red : Color.clear, lineWidth: 1.5)
                )

                // «Глаз» справа (только для isSecure)
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

            // Текст ошибки
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            LabeledInput(label: "E-mail:", placeholder: "Your e-mail", text: $email)
            LabeledInput(label: "Password:", placeholder: "Your  password", text: $password, isSecure: true)
            
            Button(action: onContinue) {             // ← ВАЖНО: вызываем onContinue
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
            
            SocialButton(title: "Continue with Apple", systemImage: "apple.logo") { }
            SocialButton(title: "Continue with Google", systemImage: "g.circle.fill") { }
        }
        // НЕТ собственного фона и ignoresSafeArea здесь
    }
}

#Preview {
    LoginView(vm: OnboardingViewModel(repository: LocalRepository(), onFinished: {}), onSuccess: { })
}
