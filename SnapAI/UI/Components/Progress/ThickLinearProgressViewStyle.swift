//
//  ThickLinearProgressViewStyle.swift
//  SnapAI
//
//  Created by Isa Melsov on 23/9/25.
//

import SwiftUI

//MARK: - ThickLinearProgressViewStyle
struct ThickLinearProgressViewStyle: ProgressViewStyle {
    var height: CGFloat = 12
    var cornerRadius: CGFloat = 6
    var fillColor: Color = .green
    var trackColor: Color = .gray.opacity(0.4)
    
    func makeBody(configuration: Configuration) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // фон (трек)
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(trackColor)
                    .frame(height: height)
                
                // прогресс
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(fillColor)
                    .frame(width: geo.size.width * CGFloat(configuration.fractionCompleted ?? 0),
                           height: height)
            }
        }
        .frame(height: height)
    }
}

