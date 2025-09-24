//
//  QuadCropSheet.swift
//  SnapAI
//
//  Created by Isa Melsov on 23/9/25.
//

import SwiftUI

//MARK: - QuadCropSheet
// Лист с кропом
struct QuadCropSheet: View {
    let image: UIImage
    let initialQuad: Quad?
    var onRetake: () -> Void
    var onUse: (UIImage) -> Void
    
    @State private var quad: Quad = .init(tl: .zero, tr: .zero, br: .zero, bl: .zero)
    @State private var imageRect: CGRect = .zero
    @State private var pendingInitial: Quad?
    @State private var isProcessing = false
    
    private let minCropSize: CGFloat = 60
    
    var body: some View {
        GeometryReader { _ in
            ZStack {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .background(Color.black)
                    .overlay(
                            GeometryReader { g in
                                Color.clear
                                    .allowsHitTesting(false)
                                    .onAppear {
                                        // контейнер кадра изображения в координатах cropSpace
                                        let container = g.frame(in: .named("cropSpace"))
                                        let fit = aspectFitRect(img: image.size, in: container.size)
                                        imageRect = fit.offsetBy(dx: container.minX, dy: container.minY)
                                    }
                                    .onChange(of: g.size) { _ in
                                        let container = g.frame(in: .named("cropSpace"))
                                        let fit = aspectFitRect(img: image.size, in: container.size)
                                        imageRect = fit.offsetBy(dx: container.minX, dy: container.minY)
                                    }
                            }
                        )
                        .allowsHitTesting(false)
                
                if imageRect.width > 0 {
                    DimOut(quad: quad)
                        .fill(Color.black.opacity(0.55), style: .init(eoFill: true))
                        .allowsHitTesting(false)
                        .zIndex(1)
                    
                    QuadShape(quad: quad)
                        .stroke(Color.white, lineWidth: 2)
                        .allowsHitTesting(false)
                        .zIndex(2)
                }
                
                Group {
                    CornerHandle(corner: .tl, quad: $quad, imageRect: imageRect, minSize: minCropSize)
                    CornerHandle(corner: .tr, quad: $quad, imageRect: imageRect, minSize: minCropSize)
                    CornerHandle(corner: .br, quad: $quad, imageRect: imageRect, minSize: minCropSize)
                    CornerHandle(corner: .bl, quad: $quad, imageRect: imageRect, minSize: minCropSize)
                }
                
                if isProcessing {
                    Color.black.opacity(0.3).ignoresSafeArea()
                    ProgressView().scaleEffect(1.2).tint(.white)
                }
            }
            .coordinateSpace(name: "cropSpace")
            .background(Color.black.ignoresSafeArea())
            .onAppear { pendingInitial = initialQuad }
            .onChange(of: imageRect) { rect in
                guard rect.width > 0, rect.height > 0 else { return }
                if let q = pendingInitial {
                    quad = clampToImage(quadFromRect(rectFromQuad(q)), in: rect)
                    pendingInitial = nil
                } else if isZero(quad) {
                    quad = quadFromRect(rect.insetBy(dx: rect.width*0.08, dy: rect.height*0.08))
                }
            }
        }
        // Внутри QuadCropSheet
        // Панель внизу поверх всего
        .overlay(alignment: .bottom) {
            HStack(spacing: 16) {
                Button("Retake", action: onRetake)
                // на время диагностики — системный стиль, чтобы исключить кастомный
                    .buttonStyle(.bordered)
                
                Button("Use") {
                    guard !isProcessing else { return }
                    isProcessing = true
                    let cropRect = rectFromQuad(quad)
                    let imgRect  = imageRect
                    DispatchQueue.global(qos: .userInitiated).async {
                        let cropped = axisAlignedCrop(image: image,
                                                      cropRectInView: cropRect,
                                                      imageRectInView: imgRect)
                        DispatchQueue.main.async {
                            isProcessing = false
                            onUse(cropped)
                        }
                    }
                }
                .buttonStyle(.borderedProminent) // системный стиль для наглядности
                .disabled(isProcessing)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(.ultraThinMaterial)
            .ignoresSafeArea(edges: .bottom)
            .zIndex(100) // ← гарантируем верхний слой
        }
        
        
        
        .interactiveDismissDisabled()
    }
    
    // helpers
    private func isZero(_ q: Quad) -> Bool { q.tl == .zero && q.tr == .zero && q.br == .zero && q.bl == .zero }
    
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
    private func clampToImage(_ q: Quad, in bounds: CGRect) -> Quad {
        let r = rectFromQuad(q).intersection(bounds)
        return quadFromRect(r)
    }
    private func aspectFitRect(img: CGSize, in container: CGSize) -> CGRect {
        let scale = min(container.width / img.width, container.height / img.height)
        let size = CGSize(width: img.width*scale, height: img.height*scale)
        let origin = CGPoint(x: (container.width - size.width)/2, y: (container.height - size.height)/2)
        return CGRect(origin: origin, size: size)
    }
    
    private func axisAlignedCrop(image: UIImage,
                                 cropRectInView: CGRect,
                                 imageRectInView: CGRect) -> UIImage {
        guard let cg = image.cgImage else { return image }
        
        // 1) Поворачиваем CIImage к той ориентации, как он показан на экране
        let exif = CGImagePropertyOrientation(image.imageOrientation)
        let oriented = CIImage(cgImage: cg).oriented(exif)
        
        // 2) Скейлим координаты из view-space в пиксели oriented CI
        let ciW = oriented.extent.width
        let ciH = oriented.extent.height
        let sx = ciW / imageRectInView.width
        let sy = ciH / imageRectInView.height
        
        func toPixel(_ p: CGPoint) -> CGPoint {
            CGPoint(x: (p.x - imageRectInView.minX) * sx,
                    y: (p.y - imageRectInView.minY) * sy)
        }
        
        let p1 = toPixel(cropRectInView.origin)
        let p2 = toPixel(CGPoint(x: cropRectInView.maxX, y: cropRectInView.maxY))
        
        let xMin = min(p1.x, p2.x)
        let xMax = max(p1.x, p2.x)
        let yMin = min(p1.y, p2.y)
        let yMax = max(p1.y, p2.y)
        
        // 3) Переводим в систему координат CI (origin снизу-слева)
        let cropCI = CGRect(
            x: floor(xMin),
            y: floor(ciH - yMax),
            width: ceil(xMax - xMin),
            height: ceil(yMax - yMin)
        ).intersection(oriented.extent)
        
        guard cropCI.width > 0, cropCI.height > 0 else { return image }
        
        // 4) Режем ориентированный CI и собираем UIImage c .up
        let ctx = CIContext()
        guard let outCG = ctx.createCGImage(oriented.cropped(to: cropCI), from: cropCI) else { return image }
        return UIImage(cgImage: outCG, scale: image.scale, orientation: .up)
    }
}

