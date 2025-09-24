//
//  QuadShape.swift
//  SnapAI
//
//  Created by Isa Melsov on 23/9/25.
//

import SwiftUI

//MARK: - QuadShape
struct QuadShape: Shape {
    let quad: Quad
    func path(in _: CGRect) -> Path {
        var p = Path()
        p.move(to: quad.tl); p.addLine(to: quad.tr); p.addLine(to: quad.br); p.addLine(to: quad.bl); p.closeSubpath()
        return p
    }
}
