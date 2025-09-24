//
//  LifestyleStep.swift
//  SnapAI
//
//  Created by Isa Melsov on 23/9/25.
//

import SwiftUI

//MARK: - LifestyleStep
struct LifestyleStep: View {
    @ObservedObject var vm: OnboardingViewModel
    @State private var selected: Lifestyle = .sedentary
    @State private var currentImage = AppImages.Activity.sedantary
    var body: some View {
        VStack {
            Text("Activity")
                .font(.system(size: 24, weight: .regular))
                .foregroundStyle(AppColors.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 26)
            
            Spacer()
            
            currentImage
                .resizable()
                .scaledToFit()
                .frame(height: 220)
                .padding(.vertical)
            
            VStack(spacing: 16) {
                lifeStyleButton(.sedentary, title: "Sedentary lifestyle")
                lifeStyleButton(.normal, title: "Normal lifestyle")
                lifeStyleButton(.active, title: "Active lifestyle")
            }
            .padding([.horizontal, .vertical], 26)
            
            Spacer()
            
            NavigationLink(destination: GoalStep(vm: vm)) {
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
        .padding()
        .background(AppColors.background.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) { BackButton() }
            ToolbarItem(placement: .principal) {
                ProgressView(value: 4, total: 5)
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
    
    @ViewBuilder
    private func lifeStyleButton(_ lifeStyle: Lifestyle, title: String) -> some View {
        let selectedState = (selected == lifeStyle)
        
        Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                selected = lifeStyle
                vm.data.lifestyle = lifeStyle
                switch lifeStyle {
                case .sedentary: currentImage = AppImages.Activity.sedantary
                case .normal: currentImage = AppImages.Activity.normal
                case .active:  currentImage = AppImages.Activity.active
                }
            }
        } label: {
            Text(title)
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(selectedState ? .white : AppColors.text)
                .frame(maxWidth: .infinity, minHeight: 60)
                .background(selectedState ? AppColors.secondary : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppColors.secondary, lineWidth: 1)
                )
                .shadow(color: .black.opacity(selectedState ? 0.0 : 0.15), radius: 3, y: 2)
        }
    }
}
