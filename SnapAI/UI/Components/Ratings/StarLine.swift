//
//  StarLine.swift
//  SnapAI
//
//  Created by Isa Melsov on 23/9/25.
//

import SwiftUI

//MARK: - StarLine
struct StarLine: View {
    @Binding var rating: Int
    var maximumRating: Int = 5
    var offColor = Color.gray
    var onColor = Color.yellow
    
    var height: CGFloat = 44
    
    var body: some View {
        HStack {
            ForEach(1..<maximumRating + 1, id: \.self) { number in
                (number <= rating ? AppImages.ButtonIcons.Star.activeStar
                 : AppImages.ButtonIcons.Star.inactiveStar)
                .resizable()
                .frame(width: 24, height: 24)
                .onTapGesture {
                    withAnimation(.interactiveSpring) {
                        rating = number
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: height/2))
        .overlay(
            RoundedRectangle(cornerRadius: height/2)
                .stroke(AppColors.primary, lineWidth: 1)
        )
        .frame(height: height)
        
        .font(.largeTitle)
    }
}
