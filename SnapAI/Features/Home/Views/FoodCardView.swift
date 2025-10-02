//
//  FoodCardView.swift
//  SnapAI
//
//  Created by Isa Melsov on 24/9/25.
//

import SwiftUI

struct FoodCardView: View {
    let meal: Meal
    let image: UIImage?
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading) {
                Text(meal.title.isEmpty ? "Untitled meal" : meal.title)
                    .foregroundStyle(AppColors.primary)
                    .font(.system(size: 16, weight: .bold))
                    .padding(.vertical, 4)
                
                Text("\(meal.calories) kcal")
                    .foregroundStyle(AppColors.primary)
                    .font(.system(size: 14, weight: .medium))
                
                HStack {
                    MetricPillCard(value: "\(meal.proteins) g",
                                   badge: .init(kind: .text("P"), color: AppColors.customBlue))
                    
                    MetricPillCard(value: "\(meal.carbs) g",
                                   badge: .init(kind: .text("C"), color: AppColors.customOrange))
                    
                    MetricPillCard(value: "\(meal.fats) g",
                                   badge: .init(kind: .text("F"), color: AppColors.customGreen))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .layoutPriority(1)
            
            
            if let image {
                CircleImage(image: image, diameter: 92)
            } else if let url = mediaURL(from: meal.imagePath) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let img):
                        img
                            .resizable()
                            .scaledToFill()
                            .frame(width: 92, height: 92)
                            .background(Circle().fill(Color.black))
                            .clipShape(Circle())
                            .overlay(Circle().stroke(.white.opacity(0.10), lineWidth: 1))
                            .shadow(color: .black.opacity(0.15), radius: 12, y: 6)
                    case .empty:
                        Circle().fill(Color.black.opacity(0.06)).frame(width: 92, height: 92)
                    case .failure:
                        CircleImage(image: .previewPlaceholder, diameter: 92)
                            .frame(width: 92, height: 92)
                        
                    @unknown default:
                        CircleImage(image: .previewPlaceholder, diameter: 92)
                            .frame(width: 92, height: 92)
                        
                    }
                }
            } else {
                CircleImage(image: image ?? .previewPlaceholder, diameter: 92)
                    .frame(width: 92, height: 92)
                
            }
            
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
    private let mediaBase = URL(string: "https://snap-ai-app.com")!
    
    /// Строит валидный HTTPS-URL для картинки с сервера.
    /// Понимает и абсолютные, и относительные пути.
    func mediaURL(from raw: String?) -> URL? {
        guard let s0 = raw?.trimmingCharacters(in: .whitespacesAndNewlines), !s0.isEmpty else { return nil }
        var s = s0

        // Если пришёл относительный путь — приклеим домен
        if s.hasPrefix("/media/") || s.hasPrefix("media/") {
            s = "https://snap-ai-app.com" + (s.hasPrefix("/") ? s : "/\(s)")
        }

        // Парсим и принудительно апгрейдим схему на https
        guard var comps = URLComponents(string: s) else { return nil }
        if comps.scheme == nil {
            comps.scheme = "https"
            comps.host = comps.host ?? "snap-ai-app.com"
        } else if comps.scheme?.lowercased() == "http" {
            comps.scheme = "https"
        }
        return comps.url
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
                .fixedSize(horizontal: true, vertical: false)
                .minimumScaleFactor(0.9)
        }
        .layoutPriority(1)
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
            .scaledToFill()
            .frame(width: diameter, height: diameter)
            .background(
                Circle().fill(Color.black)
            )
            .clipShape(Circle())
            .overlay(
                Circle().stroke(.white.opacity(0.10), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.15), radius: 12, y: 6)
    }
}

#Preview {
    FoodCardView(meal: Meal(), image: UIImage(named: "food1")!)
}
