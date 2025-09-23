import UIKit
import SwiftUI
import AVFoundation
import CoreImage
import CoreImage.CIFilterBuiltins
import CoreMedia
import ImageIO

private extension CGImagePropertyOrientation {
    init(_ ui: UIImage.Orientation) {
        switch ui {
        case .up: self = .up
        case .down: self = .down
        case .left: self = .left
        case .right: self = .right
        case .upMirrored: self = .upMirrored
        case .downMirrored: self = .downMirrored
        case .leftMirrored: self = .leftMirrored
        case .rightMirrored: self = .rightMirrored
        @unknown default: self = .up
        }
    }
}

// MARK: - Bridge

final class BridgingCoordinator: ObservableObject {
    @Published var capturedImage: UIImage?
    @Published var isTorchOn = false     // для отображения статуса в UI
}

struct HostedCameraView: UIViewControllerRepresentable {
    @ObservedObject var coordinator: BridgingCoordinator

    func makeUIViewController(context: Context) -> CameraViewController {
        CameraViewController(coordinator: coordinator)
    }

    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {
        // намеренно пусто — фонарь переключаем только через NotificationCenter
    }
}

// MARK: - Camera VC

final class CameraViewController: UIViewController, AVCapturePhotoCaptureDelegate {

    // AV
    private let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "camera.session.queue", qos: .userInitiated)
    private let output = AVCapturePhotoOutput()
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private var videoDevice: AVCaptureDevice?
    private var input: AVCaptureDeviceInput?
    
    private var cachedOrientation: AVCaptureVideoOrientation = .portrait


    // Bridge
    private let coordinator: BridgingCoordinator

    init(coordinator: BridgingCoordinator) {
        self.coordinator = coordinator
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)

        // Конфиг сессии и подготовка — строго на фоновой очереди
        sessionQueue.async { [weak self] in
            self?.configureSessionIfNeeded()
        }
    }
    
    private func updatePreviewOrientationAndCache() {
        assert(Thread.isMainThread)
        let ui = uiVideoOrientation()
        cachedOrientation = ui
        if let c = previewLayer.connection, c.isVideoOrientationSupported {
            c.videoOrientation = ui
        }
    }

    // старую currentVideoOrientation переименуем, чтобы не путать:
    private func uiVideoOrientation() -> AVCaptureVideoOrientation {
        let interface = view.window?.windowScene?.interfaceOrientation ?? .portrait
        switch interface {
        case .portrait: return .portrait
        case .portraitUpsideDown: return .portraitUpsideDown
        case .landscapeLeft: return .landscapeRight
        case .landscapeRight: return .landscapeLeft
        default: return .portrait
        }
    }

    private var isConfigured = false
    private func configureSessionIfNeeded() {
        guard !isConfigured else { return }
        session.beginConfiguration()
        session.sessionPreset = .photo

        // input
        if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
           let input = try? AVCaptureDeviceInput(device: device),
           session.canAddInput(input) {
            session.addInput(input)
            self.videoDevice = device
            self.input = input
        }

        // output
        if session.canAddOutput(output) {
            session.addOutput(output)
            output.maxPhotoQualityPrioritization = .speed

            if let dev = self.videoDevice {
                let supported = dev.activeFormat.supportedMaxPhotoDimensions
                let sorted = supported.sorted { max($0.width, $0.height) < max($1.width, $1.height) }
                let cap: Int32 = 2048
                let chosen = (sorted.last { max($0.width, $0.height) <= cap }) ?? (sorted.first ?? sorted.last!)
                output.maxPhotoDimensions = chosen
            }
        }

        session.commitConfiguration()
        isConfigured = true
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer.frame = view.bounds
        updatePreviewOrientationAndCache()
    }
    
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to:size, with: coordinator)
        coordinator.animate(alongsideTransition: nil) { _ in
            self.updatePreviewOrientationAndCache()   // <-- МЕЙН
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // единственный слушатель нотификаций — VC
        NotificationCenter.default.addObserver(self, selector: #selector(takePhotoAction), name: .takePhoto, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(toggleTorchNote(_:)), name: .toggleTorch, object: nil)

        // запуск сессии на бэке
        sessionQueue.async { [weak self] in
            guard let self else { return }
            self.configureSessionIfNeeded()
            if !self.session.isRunning { self.session.startRunning() }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)

        // остановка сессии на бэке
        sessionQueue.async { [weak self] in
            guard let self else { return }
            if self.session.isRunning { self.session.stopRunning() }
        }
    }


    // MARK: - Torch

    @objc private func toggleTorchNote(_ note: Notification) {
        let on = note.object as? Bool ?? false
        setTorch(on: on)
    }

    func setTorch(on: Bool) {
        sessionQueue.async {
            guard let device = self.videoDevice, device.hasTorch else { return }
            do {
                try device.lockForConfiguration()
                device.torchMode = on ? .on : .off
                device.unlockForConfiguration()
            } catch {
                print("Torch configuration error: \(error)")
            }
        }
    }

    // MARK: - Capture

    @objc private func takePhotoAction() { capture() }

    func capture() {
        sessionQueue.async {
            guard self.session.isRunning else { return }

            if let conn = self.output.connection(with: .video),
               conn.isVideoOrientationSupported {
                conn.videoOrientation = self.cachedOrientation   // <-- только кэш
            }

            let settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
            settings.photoQualityPrioritization = .speed
            self.output.capturePhoto(with: settings, delegate: self)
        }
    }

    // MARK: - AVCapturePhotoCaptureDelegate

    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {
        guard error == nil, let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else { return }
        DispatchQueue.main.async {
            self.coordinator.capturedImage = image
        }
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let takePhoto = Notification.Name("snapai.takePhoto")
    static let toggleTorch = Notification.Name("snapai.toggleTorch")
}

// MARK: - SwiftUI Camera Screen

struct CameraScreen: View {
    @Environment(\.dismiss) private var dismiss
    var onDone: (UIImage) -> Void

    @StateObject private var bridge = BridgingCoordinator()
    private struct CropItem: Identifiable, Equatable {
        let id = UUID()
        let image: UIImage
    }

    @State private var cropItem: CropItem?   // вместо showCrop + cropImage


    @State private var detectedQuad: Quad?

    var body: some View {
        ZStack {
            HostedCameraView(coordinator: bridge)
                .ignoresSafeArea()

            // верхняя панель
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(.black.opacity(0.35))
                        .clipShape(Circle())
                }
                Spacer()
                Button {
                    bridge.isTorchOn.toggle()
                    NotificationCenter.default.post(name: .toggleTorch, object: bridge.isTorchOn)
                } label: {
                    Text(bridge.isTorchOn ? "Torch On" : "Torch Off")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(.black.opacity(0.35))
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .frame(maxHeight: .infinity, alignment: .top)
            .ignoresSafeArea()

            // нижняя панель
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        NotificationCenter.default.post(name: .takePhoto, object: nil)
                    } label: {
                        ZStack {
                            Circle().fill(Color.white.opacity(0.2)).frame(width: 78, height: 78)
                            Circle().strokeBorder(Color.white, lineWidth: 3).frame(width: 74, height: 74)
                            Circle().fill(Color.white).frame(width: 60, height: 60)
                        }
                    }
                    .buttonStyle(.plain)
                    Spacer()
                }
                .padding(.bottom, 28)
            }
            .ignoresSafeArea()

            // верхняя виньетка (читаемость кнопок)
            LinearGradient(colors: [.black.opacity(0.45), .clear], startPoint: .top, endPoint: .center)
                .ignoresSafeArea()
                .allowsHitTesting(false)
        }
        .onChange(of: bridge.capturedImage) { img in
            guard let img else { return }
            cropItem = .init(image: img)   // ЭТО и есть триггер показа
        }
        .fullScreenCover(item: $cropItem) { item in
            QuadCropSheet(
                image: item.image,
                initialQuad: nil,
                onRetake: {
                    cropItem = nil
                    bridge.capturedImage = nil
                },
                onUse: { cropped in
                    cropItem = nil
                    onDone(cropped)
                }
            )
            .preferredColorScheme(.dark)
        }

    }
}

// MARK: - Crop UI

struct Quad {
    var tl: CGPoint
    var tr: CGPoint
    var br: CGPoint
    var bl: CGPoint
}

// Уголки
private struct CornerHandle: View {
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
            .frame(width: 44, height: 44)  // hit-area
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

// затемнение вне полигона (не перехватывает тапы)
private struct DimOut: Shape {
    let quad: Quad
    func path(in r: CGRect) -> Path {
        var p = Path(r)
        var q = Path()
        q.move(to: quad.tl); q.addLine(to: quad.tr); q.addLine(to: quad.br); q.addLine(to: quad.bl); q.closeSubpath()
        p.addPath(q)
        return p
    }
}

private struct QuadShape: Shape {
    let quad: Quad
    func path(in _: CGRect) -> Path {
        var p = Path()
        p.move(to: quad.tl); p.addLine(to: quad.tr); p.addLine(to: quad.br); p.addLine(to: quad.bl); p.closeSubpath()
        return p
    }
}

// MARK: - Demo

struct DemoRootView: View {
    @State private var showCamera = false
    @State private var lastShot: UIImage?

    var body: some View {
        VStack(spacing: 20) {
            if let img = lastShot {
                Image(uiImage: img)
                    .resizable().scaledToFit()
                    .frame(height: 300)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(.secondary, lineWidth: 1))
            } else {
                Text("No image yet").foregroundColor(.secondary)
            }

            Button("Open Camera") { showCamera = true }
                .font(.headline)
                .frame(maxWidth: .infinity, minHeight: 52)
                .foregroundColor(.white)
                .background(Color.accentColor)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 20)
        }
        .padding()
        .fullScreenCover(isPresented: $showCamera) {
                    CameraFlow()   // <-- тут весь сценарий (камера -> детали)
                }
    }
}




struct CapsuleButtonStyle: ButtonStyle {
    enum Role { case primary, secondary, outline, destructive
        case custom(bg: Color, fg: Color = .white, border: Color = .clear, borderWidth: CGFloat = 0)
    }
    enum Size { case large, medium, small }

    var role: Role = .primary
    var size: Size = .large

    // ✅ Явный инициализатор для роли
    init(role: Role = .primary, size: Size = .large) {
        self.role = role
        self.size = size
    }

    // Твой кастомный инициализатор по бэкграунду
    init(background: Color, size: Size = .large, foreground: Color = .white) {
        self.role = .custom(bg: background, fg: foreground)
        self.size = size
    }

    func makeBody(configuration: Configuration) -> some View { /* как было */ }
}

// Сахар
extension ButtonStyle where Self == CapsuleButtonStyle {
    static func capsule(_ role: CapsuleButtonStyle.Role = .primary,
                        size: CapsuleButtonStyle.Size = .large) -> CapsuleButtonStyle {
        CapsuleButtonStyle(role: role, size: size)   // ✅ теперь существует
    }
}


struct CameraFlow: View {
    enum Step {
        case camera
        case detail(UIImage)
    }

    @State private var step: Step = .camera
    @StateObject private var vm = MealViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Group {
            switch step {
            case .camera:
                CameraScreen { cropped in
                    let normalized = cropped.normalizedUp(maxDimension: 2048)
                    step = .detail(normalized)
                }
                .statusBarHidden(true)

            case .detail(let img):
                MealDetailScreen(image: img, vm: vm)
                    .toolbar {            // кнопка закрытия шита
                        ToolbarItem(placement: .topBarLeading) {
                            Button {
                                dismiss()
                            } label: {
                                Image(systemName: "xmark")
                            }
                        }
                    }
            }
        }
    }
}

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



#Preview("Main") {
    NavigationStack {
        DemoRootView().preferredColorScheme(.dark)
    }
}
