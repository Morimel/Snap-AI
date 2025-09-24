//
//  GenderStep.swift
//  SnapAI
//
//  Created by Isa Melsov on 23/9/25.
//

import SwiftUI

//MARK: - GenderStep
struct GenderStep: View {
    @ObservedObject var vm: OnboardingViewModel
    @State private var selected: Gender = .male   // текущий выбор
    @State private var currentImage = AppImages.Gender.male
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Select your gender")
                .font(.system(size: 24, weight: .regular))
                .foregroundStyle(AppColors.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 26)
            
            currentImage
                .resizable()
                .scaledToFit()
                .frame(height: 300)
                .padding(.top, -8)
            
            HStack(spacing: 16) {
                genderButton(.male, title: "Male")
                genderButton(.female, title: "Female")
            }
            .padding(.horizontal, 26)
            
            genderButton(.other, title: "Other")
                .padding(.horizontal, 26)
            
            Spacer()
            
            NavigationLink(destination: WeightHeightStep(vm: vm)) {
                Text("Next")
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 60)
                    .foregroundColor(.white)
                    .background(AppColors.secondary)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
            }
            .padding(.horizontal, 26)
            .padding(.bottom, 28)
        }
        .background(AppColors.background.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) { BackButton() }
            ToolbarItem(placement: .principal) {
                ProgressView(value: 1, total: 5)
                    .progressViewStyle(
                        ThickLinearProgressViewStyle(
                            height: 10, cornerRadius: 7,
                            fillColor: AppColors.primary, trackColor: AppColors.secondary
                        )
                    )
                    .frame(width: UIScreen.main.bounds.width * 0.6, height: 10)
                    .padding(.top, 2)
            }
        }
    }
    
    // MARK: - UI helpers
    
    @ViewBuilder
    private func genderButton(_ gender: Gender, title: String) -> some View {
        let selectedState = (selected == gender)
        
        Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                selected = gender
                vm.data.gender = gender
                switch gender {
                case .male:   currentImage = AppImages.Gender.male
                case .female: currentImage = AppImages.Gender.female
                case .other:  currentImage = AppImages.Gender.other
                }
            }
        } label: {
            Text(title)
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(selectedState ? .white : AppColors.text)
                .frame(maxWidth: .infinity, minHeight: 60)
                .background(selectedState ? AppColors.secondary : Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppColors.secondary, lineWidth: 1)
                )
                .shadow(color: .black.opacity(selectedState ? 0.0 : 0.15), radius: 3, y: 2)
        }
    }
}
