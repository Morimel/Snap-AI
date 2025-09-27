//
//  ReviewCards.swift
//  SnapAI
//
//  Created by Isa Melsov on 23/9/25.
//

import SwiftUI

//MARK: - ReviewCard
struct ReviewCard: View {
    
    let avatarName: String
    let author: String
    let text: String
    let rating: Int
    
    var body: some View {
        VStack {
            HStack {
                Image(avatarName)
                    .resizable()
                    .frame(width: 60, height: 60)
                    .padding(.vertical, 24)
                
                Text(author)
                    .font(.system(size: 12, weight: .medium))
            }
            
            Text(text)
                .foregroundStyle(.black)
                .font(.system(size: 12, weight: .regular))
                .padding()
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
            
            HStack {
                ForEach(0..<5) { _ in
                    Image(systemName: "star.fill").foregroundColor(Color.yellow)
                }
            }
            .padding(.vertical, 24)
        }
        .padding(.horizontal, 4)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
