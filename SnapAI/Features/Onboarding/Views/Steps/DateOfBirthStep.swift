//
//  DateOfBirthStep.swift
//  SnapAI
//
//  Created by Isa Melsov on 23/9/25.
//

import SwiftUI

//MARK: - DateOfBirthStep
struct DateOfBirthStep: View {
    @ObservedObject var vm: OnboardingViewModel
    @State private var selectedDate: Date?
    var body: some View {
        VStack {
            Text("Date of birth")
                .font(.system(size: 24, weight: .regular))
                .foregroundStyle(AppColors.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 40)
            
            Spacer()
            
            DateWheelPicker()
            
            Spacer()
            
            NavigationLink(destination: LifestyleStep(vm: vm)) {
                Text("Next")
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 60)
                    .foregroundColor(.white)
                    .background(AppColors.secondary)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 28)
            .onAppear {
                //                    vm.data.weight = Double(weightText)
                //                    vm.data.height = Double(heightText)
            }
            
        }
        .padding()
        .background(AppColors.background.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) { BackButton() }
            ToolbarItem(placement: .principal) {
                ProgressView(value: 3, total: 5)
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
