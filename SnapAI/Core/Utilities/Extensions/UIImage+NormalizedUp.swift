//
//  UIImage+NormalizedUp.swift
//  SnapAI
//
//  Created by Isa Melsov on 23/9/25.
//

import UIKit

//MARK: - UIImage
extension UIImage {
    /// Рисует изображение в .up и при желании даунскейлит по длинной стороне до maxDimension.
    func normalizedUp(maxDimension: CGFloat? = nil) -> UIImage {
        let targetSize: CGSize = {
            guard let maxDim = maxDimension else { return self.size }
            let longest = Swift.max(self.size.width, self.size.height)
            let scale = Swift.min(maxDim / longest, 1.0)   // только даунскейл
            return CGSize(width: self.size.width * scale,
                          height: self.size.height * scale)
        }()

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = self.scale          // можно 1.0, если хочешь управлять пикселями вручную
        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)

        return renderer.image { _ in
            UIColor.clear.setFill()
            UIBezierPath(rect: CGRect(origin: .zero, size: targetSize)).fill()

            // Вписываем исходное изображение (с учётом его EXIF-ориентации)
            let s = Swift.min(targetSize.width / self.size.width,
                              targetSize.height / self.size.height)
            let drawSize = CGSize(width: self.size.width * s,
                                  height: self.size.height * s)
            let origin = CGPoint(x: (targetSize.width - drawSize.width) / 2,
                                 y: (targetSize.height - drawSize.height) / 2)
            self.draw(in: CGRect(origin: origin, size: drawSize))
        }
    }
}
