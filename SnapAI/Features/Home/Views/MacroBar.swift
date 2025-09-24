//
//  MacroBar.swift
//  SnapAI
//
//  Created by Isa Melsov on 23/9/25.
//

import SwiftUI

//MARK: - MacroBar
struct MacroBar: View {
    let title: String
    let current: Double
    let target: Double
    let gradient: LinearGradient
    
    private let barHeight: CGFloat = 6
    private let knobSize: CGFloat = 8
    
    var fraction: CGFloat {
        guard target > 0 else { return 0 }
        return CGFloat(min(max(current / target, 0), 1))
    }
    
    var body: some View {
        VStack(spacing: 10) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(AppColors.primary)
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.black.opacity(0.06))
                        .frame(height: barHeight)
                    
                    // заполнение
                    Capsule()
                        .fill(gradient)
                        .frame(width: geo.size.width * fraction, height: barHeight)
                    
                    // «ползунок»-индикатор
                    Circle()
                        .fill(.white)
                        .overlay(
                            Circle().stroke(Color.black.opacity(0.35), lineWidth: 1)
                        )
                        .frame(width: knobSize, height: knobSize)
                        .offset(x: max(0, (geo.size.width - knobSize) * fraction))
                }
                .animation(.easeInOut(duration: 0.25), value: fraction)
            }
            .frame(height: knobSize)
            
            Text("\(Int(current)) / \(Int(target))g")
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(AppColors.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

