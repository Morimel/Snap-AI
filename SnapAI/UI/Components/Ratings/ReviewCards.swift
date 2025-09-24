//
//  ReviewCards.swift
//  SnapAI
//
//  Created by Isa Melsov on 23/9/25.
//

import SwiftUI

//MARK: - ReviewCards
struct ReviewCards: View {
    var body: some View {
        VStack {
            HStack {
                Image("review1")
                    .resizable()
                    .frame(width: 60, height: 60)
                    .padding(.vertical, 24)
                
                Text("Michael Brooks")
                    .font(.system(size: 12, weight: .medium))
            }
            
            Text("I was shocked! I just snapped a\nphoto of my food, and Snap AI\ninstantly counted the calories!")
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
