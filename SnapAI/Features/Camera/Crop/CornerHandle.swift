//
//  CornerHandle.swift
//  SnapAI
//
//  Created by Isa Melsov on 23/9/25.
//

import SwiftUI

//MARK: - CornerHandle
struct CornerHandle: View {
    enum Corner { case tl, tr, br, bl }

    let corner: Corner
    @Binding var quad: Quad
    let imageRect: CGRect
    let minSize: CGFloat

    @State private var startRect: CGRect?

    var body: some View {
        let r = rectFromQuad(quad)
        let p: CGPoint = {
            switch corner {
            case .tl: return r.origin
            case .tr: return CGPoint(x: r.maxX, y: r.minY)
            case .br: return CGPoint(x: r.maxX, y: r.maxY)
            case .bl: return CGPoint(x: r.minX, y: r.maxY)
            }
        }()

        Circle().fill(Color.white)
            .frame(width: 24, height: 24)
            .shadow(radius: 2, y: 1)
            .frame(width: 44, height: 44)
            .contentShape(Circle())
            .position(p)
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .named("cropSpace"))
                    .onChanged { value in
                        guard imageRect.width > 0, imageRect.height > 0 else { return }
                        if startRect == nil { startRect = rectFromQuad(quad) }
                        guard let s = startRect else { return }

                        let x = max(imageRect.minX, min(imageRect.maxX, value.location.x))
                        let y = max(imageRect.minY, min(imageRect.maxY, value.location.y))

                        var new = s
                        switch corner {
                        case .tl:
                            let nx = min(x, s.maxX - minSize)
                            let ny = min(y, s.maxY - minSize)
                            new.origin.x = nx
                            new.origin.y = ny
                            new.size.width  = s.maxX - nx
                            new.size.height = s.maxY - ny
                        case .tr:
                            let nx = max(x, s.minX + minSize)
                            let ny = min(y, s.maxY - minSize)
                            new.origin.x = s.minX
                            new.origin.y = ny
                            new.size.width  = nx - s.minX
                            new.size.height = s.maxY - ny
                        case .br:
                            let nx = max(x, s.minX + minSize)
                            let ny = max(y, s.minY + minSize)
                            new.origin = CGPoint(x: s.minX, y: s.minY)
                            new.size   = CGSize(width: nx - s.minX, height: ny - s.minY)
                        case .bl:
                            let nx = min(x, s.maxX - minSize)
                            let ny = max(y, s.minY + minSize)
                            new.origin.x = nx
                            new.origin.y = s.minY
                            new.size.width  = s.maxX - nx
                            new.size.height = ny - s.minY
                        }

                        new = clampRect(new, in: imageRect, minSize: minSize)
                        quad = quadFromRect(new)
                    }
                    .onEnded { _ in startRect = nil }
            )
            .zIndex(20)
    }

    // helpers
    private func rectFromQuad(_ q: Quad) -> CGRect {
        let xs = [q.tl.x, q.tr.x, q.br.x, q.bl.x]
        let ys = [q.tl.y, q.tr.y, q.br.y, q.bl.y]
        let minX = xs.min() ?? 0, maxX = xs.max() ?? 0
        let minY = ys.min() ?? 0, maxY = ys.max() ?? 0
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }
    private func quadFromRect(_ r: CGRect) -> Quad {
        Quad(tl: r.origin,
             tr: CGPoint(x: r.maxX, y: r.minY),
             br: CGPoint(x: r.maxX, y: r.maxY),
             bl: CGPoint(x: r.minX, y: r.maxY))
    }
    private func clampRect(_ r: CGRect, in bounds: CGRect, minSize: CGFloat) -> CGRect {
        var out = r
        if out.width < minSize {
            if corner == .tl || corner == .bl { out.origin.x = out.maxX - minSize }
            out.size.width = minSize
        }
        if out.height < minSize {
            if corner == .tl || corner == .tr { out.origin.y = out.maxY - minSize }
            out.size.height = minSize
        }
        if out.minX < bounds.minX { out.origin.x = bounds.minX }
        if out.minY < bounds.minY { out.origin.y = bounds.minY }
        if out.maxX > bounds.maxX { out.origin.x = bounds.maxX - out.width }
        if out.maxY > bounds.maxY { out.origin.y = bounds.maxY - out.height }
        return out
    }
}
