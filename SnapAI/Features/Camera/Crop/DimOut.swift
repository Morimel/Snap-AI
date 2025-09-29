//
//  DimOut.swift
//  SnapAI
//
//  Created by Isa Melsov on 23/9/25.
//

import SwiftUI

//MARK: - DimOut
struct DimOut: Shape {
    let quad: Quad
    func path(in r: CGRect) -> Path {
        var p = Path(r)
        var q = Path()
        q.move(to: quad.tl); q.addLine(to: quad.tr); q.addLine(to: quad.br); q.addLine(to: quad.bl); q.closeSubpath()
        p.addPath(q)
        return p
    }
}
