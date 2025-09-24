//
//  UIImage+Solid.swift
//  SnapAI
//
//  Created by Isa Melsov on 23/9/25.
//

import UIKit

extension UIImage {
    static func solid(color: UIColor, size: CGSize = .init(width: 900, height: 600)) -> UIImage {
        let r = UIGraphicsImageRenderer(size: size)
        return r.image { ctx in
            color.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }
    }
}

