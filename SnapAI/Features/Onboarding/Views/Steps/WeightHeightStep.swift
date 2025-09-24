//
//  WeightHeightStep.swift
//  SnapAI
//
//  Created by Isa Melsov on 23/9/25.
//

import SwiftUI

//MARK: - WeightHeightStep
struct WeightHeightStep: View {
    @ObservedObject var vm: OnboardingViewModel
    @State private var weightText = ""
    @State private var heightText = ""
    @State private var unit: UnitSystem = .imperial
    var body: some View {
        VStack(spacing: 16) {
            Text("Weight and Height")
                .font(.system(size: 24, weight: .regular))
                .foregroundStyle(AppColors.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 26)
            
            Spacer()
            
            BubbleSegmentedControl(vm: vm, height: 48)
                .padding(.horizontal, 26)
            
            
            Text("Weight")
                .font(.system(size: 24, weight: .regular))
                .foregroundStyle(AppColors.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 26)
            
            UnitTextField(vm: vm, placeholder: "Your weight", text: $weightText, kind: .weight)
            
                .padding(.horizontal, 26)
            
            
            
            
            Text("Height")
                .font(.system(size: 24, weight: .regular))
                .foregroundStyle(AppColors.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 26)
            
            UnitTextField(vm: vm, placeholder: "Your height", text: $heightText, kind: .height)
            
                .padding(.horizontal, 26)
            
            Spacer()
            
            NavigationLink(destination: DateOfBirthStep(vm: vm)) {
                Text("Next")
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 60)
                    .foregroundColor(.white)
                    .background(AppColors.secondary)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
            }
            .padding(.horizontal, 26)
            .padding(.bottom, 28)
            .onAppear {
                vm.data.weight = Double(weightText)
                vm.data.height = Double(heightText)
            }
        }
        .padding()
        .background(AppColors.background.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) { BackButton() }
            ToolbarItem(placement: .principal) {
                ProgressView(value: 2, total: 5)
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
}
