//
//  MeetingScreen.swift
//  SnapAI
//
//  Created by Isa Melsov on 24/9/25.
//

import SwiftUI

//MARK: - StartStep
struct MeetingScreen: View {
    @ObservedObject var vm: OnboardingViewModel
    @State private var focalYOffset: CGFloat = 0
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        GeometryReader { geo in
            ZStack {
                ZStack() {
                    AppImages.OtherImages.food1
                        .resizable()
                        .scaledToFill()
                        .frame(height: geo.size.height * 1.1)
                        .clipped()
                        .offset(y: focalYOffset)
                    
                    Spacer(minLength: 0)
                }
                VStack(spacing: 16) {
                    
                    HStack {
                        CircleIconButton {
                            dismiss()
                        }
                        Spacer()
                    }
                    
                    Text("Nice to meet you!")
                        .fontWeight(.regular)
                        .foregroundColor(AppColors.primary)
                        .font(.system(size: 36))
                    
                    
                    Text("Already have an account?")
                        .multilineTextAlignment(.center)
                        .foregroundColor(AppColors.text)
                    
                    // LOGIN
                    NavigationLink(value: OnbRoute.login) {
                        Text("Login")
                            .font(.headline)
                            .frame(maxWidth: .infinity, minHeight: 56)
                            .foregroundStyle(.white)
                            .background(AppColors.secondary)
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                    }
                    .buttonStyle(.plain)
                    
                    // REGISTER
                    NavigationLink(value: OnbRoute.register) {
                        Text("Create account")
                            .font(.headline)
                            .frame(maxWidth: .infinity, minHeight: 56)
                            .foregroundStyle(AppColors.primary)
                            .background(AppColors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                            .overlay(
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(AppColors.primary.opacity(0.10), lineWidth: 1)
                            )
                            .shadow(color: AppColors.primary.opacity(0.08), radius: 16, y: -2)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
                .frame(height: geo.size.height * 0.42)
                .frame(maxWidth: .infinity)
                .background(AppColors.background)
                .clipShape(RoundedRectangle(cornerRadius: 28))
                .shadow(color: .black.opacity(0.08), radius: 12, y: -2)
                .offset(y: 8)
                .frame(maxHeight: .infinity, alignment: .bottom)
            }
            .ignoresSafeArea()
        }
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    MeetingScreen(vm: OnboardingViewModel(repository: LocalRepository(), onFinished: {}))
}
