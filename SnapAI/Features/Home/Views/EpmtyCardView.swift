//
//  EpmtyCardView.swift
//  SnapAI
//
//  Created by Isa Melsov on 23/9/25.
//

import SwiftUI

//MARK: - EpmtyCardView
struct EpmtyCardView: View {
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Nothing here yet!")
                    .foregroundStyle(AppColors.primary)
                    .font(.system(size: 16, weight: .bold))
                    .padding(.vertical, 12)
                
                Text("Add something delicious\nand treat yourself to a new\ndish!")
                    .foregroundStyle(AppColors.primary)
                    .font(.system(size: 14, weight: .medium))
            }
            
            .padding(.horizontal)
            .padding(.vertical, 12)
            
            AppImages.Other.plateApple
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
        }
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(.white)
            
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(Color.black.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.06), radius: 10, y: 4)
        .padding(.horizontal)
        
    }
}
