//
//  BubbleSegmentedControl.swift
//  SnapAI
//
//  Created by Isa Melsov on 23/9/25.
//

import SwiftUI

//MARK: - BubbleSegmentedControl
struct BubbleSegmentedControl: View {
    @ObservedObject var vm: OnboardingViewModel
    var height: CGFloat = 44
    
    var body: some View {
        HStack(spacing: 12) {
            seg("Imperial", .imperial)
            
            seg("Metric", .metric)
        }
        .frame(maxWidth: .infinity)
        .padding(8)
        .background(AppColors.background)
        .clipShape(RoundedRectangle(cornerRadius: height/2))
        .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 2)
        .frame(height: height)
    }
    
    @ViewBuilder
    private func seg(_ title: String, _ unit: UnitSystem) -> some View {
        let isSelected = vm.data.unit == unit
        
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                vm.data.unit = unit
            }
        } label: {
            Text(title)
                .frame(maxWidth: .infinity)
                .font(.system(size: 16, weight: isSelected ? .bold : .regular))
                .foregroundColor(isSelected ? .white : AppColors.text)
                .frame(maxWidth: .infinity, minHeight: height - 20)
                .background(isSelected ? AppColors.primary : Color.clear)
                .clipShape(Capsule())
                .contentShape(Rectangle())
        }
    }
}
