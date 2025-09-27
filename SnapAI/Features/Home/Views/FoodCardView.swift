//
//  FoodCardView.swift
//  SnapAI
//
//  Created by Isa Melsov on 24/9/25.
//

import SwiftUI

struct FoodCardView: View {
    
    let image: UIImage

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading) {
                Text("Teriyaki chicken with rice")
                    .foregroundStyle(AppColors.primary)
                    .font(.system(size: 16, weight: .bold))
                    .padding(.vertical, 4)
                
                Text("\(291) kcal")
                    .foregroundStyle(AppColors.primary)
                    .font(.system(size: 14, weight: .medium))
                
                HStack {
                    MetricPillCard(value: "50 g",
                                   badge: .init(kind: .text("P"), color: .blue))
                    
                    MetricPillCard(value: "50 g",
                                   badge: .init(kind: .text("P"), color: .blue))
                    
                    MetricPillCard(value: "50 g",
                                   badge: .init(kind: .text("P"), color: .blue))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .layoutPriority(1)                 // ← важнее, чем картинка

            
            CircleImage(image: image, diameter: 92)   // ← фиксируем размер
                .frame(width: 92, height: 92)

        }
        .padding()
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

struct MetricPillCard: View {
    let value: String
    var badge: MetricBadge? = nil

    var body: some View {
        HStack(spacing: 8) {
            if let badge { BadgeView(badge: badge) }
            Text(value)
                .font(.caption.bold())
                .foregroundStyle(AppColors.primary)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false) // ← не сжимать в ширину
                .minimumScaleFactor(0.9)                       // (на всякий случай)
        }
        .layoutPriority(1)                                     // ← держим место
    }
}


struct CircleImage: View {
    let image: UIImage
    var diameter: CGFloat = 100

    var body: some View {
        Image(uiImage: image)
            .resizable()
            .interpolation(.high)
            .antialiased(true)
            .scaledToFill()                      // центр-кроп
            .frame(width: diameter, height: diameter)
            .background(                         // фон, если фото узкое/высокое
                Circle().fill(Color.black)
            )
            .clipShape(Circle())                 // делаем круг
            .overlay(                            // тонкий контур (необязательно)
                Circle().stroke(.white.opacity(0.10), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.15), radius: 12, y: 6)
    }
}

#Preview {
    FoodCardView(image: UIImage(named: "food1")!)
}
