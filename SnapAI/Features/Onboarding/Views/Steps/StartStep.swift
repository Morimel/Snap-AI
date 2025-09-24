//
//  StartStep.swift
//  SnapAI
//
//  Created by Isa Melsov on 23/9/25.
//

import SwiftUI

//MARK: - StartStep
struct StartStep: View {
    @ObservedObject var vm: OnboardingViewModel
    @State private var focalYOffset: CGFloat = 0
    var body: some View {
        GeometryReader { geo in
            ZStack {
                VStack(spacing: 0) {
                    AppImages.Other.food1
                        .resizable()
                        .scaledToFill()
                        .frame(height: geo.size.height * 0.80)
                        .clipped()
                        .offset(y: focalYOffset)
                    Spacer(minLength: 0)
                }
                VStack(spacing: 16) {
                    
                    Spacer()
                    
                    Group {
                        Text("Welcome to ")
                            .fontWeight(.regular)
                            .foregroundColor(AppColors.primary) +
                        Text("Snap AI")
                            .fontWeight(.bold)
                            .foregroundColor(AppColors.primary)
                    }
                    .font(.system(size: 36))
                    
                    Spacer()
                    
                    Text("Count calories from a photo in just 1 click")
                        .multilineTextAlignment(.center)
                        .foregroundColor(AppColors.text)
                    
                    NavigationLink(destination: GenderStep(vm: vm)) {
                        Text("Get Started")
                            .font(.headline)
                            .frame(maxWidth: .infinity, minHeight: 56)
                            .foregroundColor(.white)
                            .background(AppColors.secondary)
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                    }
                    .padding(.bottom, 28)
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
    }
}
