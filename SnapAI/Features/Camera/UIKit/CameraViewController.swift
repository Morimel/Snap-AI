//
//  UIKit.swift
//  SnapAI
//
//  Created by Isa Melsov on 23/9/25.
//

import UIKit
import SwiftUI
import AVFoundation

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

