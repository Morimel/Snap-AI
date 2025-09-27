//
//  FixedHeaderImage.swift
//  SnapAI
//
//  Created by Isa Melsov on 23/9/25.
//

import SwiftUI

struct FixedHeaderImage: View {
    let image: UIImage
    static let height: CGFloat = 380

    var body: some View {
        ZStack {                // фон, если картинка уже узкая/высокая
            Color.black
            Image(uiImage: image)
                .resizable()
                .interpolation(.high)
                .antialiased(true)
                .scaledToFill() // центр-кроп внутри фиксированного контейнера
        }
        .frame(maxWidth: .infinity)
        .frame(height: Self.height)
    }
}
