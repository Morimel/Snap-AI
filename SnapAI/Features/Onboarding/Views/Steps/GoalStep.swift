//
//  GoalStep.swift
//  SnapAI
//
//  Created by Isa Melsov on 23/9/25.
//

import SwiftUI

//MARK: - GoalStep
struct GoalStep: View {
    @ObservedObject var vm: OnboardingViewModel
    @State private var desiredWeightText = ""
    @State private var selected: Goal = .lose
    var body: some View {
        VStack(spacing: 16) {
            
            Text("Goal")
                .font(.system(size: 24, weight: .regular))
                .foregroundStyle(AppColors.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 26)
            // картинка по полу
            vm.data.genderImage
                .resizable()
                .scaledToFit()
                .frame(height: 220)
            
            
            HStack(spacing: 6) {
                goalButton(.lose, title: "Lose weight")
                goalButton(.gain, title: "Gain weight")
                goalButton(.maintain, title: "Maintain weight")
            }
            .padding([.horizontal, .vertical], 26)
            
            Spacer()
            
            // только желаемый вес (юниты из vm.data.unit)
            UnitTextField(vm: vm,
                          placeholder: "Enter your desired weight",
                          text: $desiredWeightText,
                          kind: .weight)
            .padding(.horizontal, 26)
            .onChange(of: desiredWeightText) { v in
                vm.data.desiredWeight = v
                    .replacingOccurrences(of: ",", with: ".")
                    .doubleValue
            }
            
            
            Spacer()
            
            // дальше идём на экран Rate (оценка в App Store)
            NavigationLink {
                RateStep(vm: vm)   // <- твой экран с оценкой приложения
            } label: {
                Text("Next")
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 56)
                    .foregroundColor(.white)
                    .background(AppColors.secondary)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
            }
            .simultaneousGesture(TapGesture().onEnded { vm.saveDraft() })
            .padding(.horizontal, 26)
            .padding(.top, 8)
        }
        .padding(.top, 8)
        .background(AppColors.background.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) { BackButton() }
            ToolbarItem(placement: .principal) {
                ProgressView(value: 5.0, total: 5.0)
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
    private func goalButton(_ goal: Goal, title: String) -> some View {
        let selectedState = (selected == goal)
        
        Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                selected = goal
                vm.data.goal = goal
            }
        } label: {
            Text(title)
                .font(.system(size: 14, weight: selectedState ? .semibold : .regular))
                .foregroundColor(selectedState ? .white : AppColors.primary)
                .frame(maxWidth: .infinity, minHeight: 40)
                .background(selectedState ? AppColors.primary : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(AppColors.primary, lineWidth: 1)
                )
                .shadow(color: .black.opacity(selectedState ? 0.0 : 0.15), radius: 3, y: 2)
        }
    }
}
