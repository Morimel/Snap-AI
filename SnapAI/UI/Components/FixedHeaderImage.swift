//
//  FixedHeaderImage.swift
//  SnapAI
//
//  Created by Isa Melsov on 23/9/25.
//

import SwiftUI

struct FixedHeaderImage: View {
    let image: UIImage
    /// Границы, чтобы не расползалось и не становилось слишком мелким
    var minH: CGFloat = 200
    var maxH: CGFloat = 380
    /// Отношение высоты к ширине контейнера
    var heightRatio: CGFloat = 0.6  // ~3:5

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = min(max(minH, w * heightRatio), maxH)

            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: w, height: h)
                .clipped()
                .overlay(
                    LinearGradient(colors: [.black.opacity(0.22), .clear],
                                   startPoint: .top, endPoint: .center)
                )
                .frame(height: h, alignment: .center) // фиксируем высоту ячейки
        }
        .frame(height: max(minH, min(maxH, heightRatio * UIScreen.main.bounds.width)))
        // ↑ внешняя рамка даёт стабильную высоту до замера GeometryReader
    }
}
