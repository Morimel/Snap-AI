//
//  UIKit.swift
//  SnapAI
//
//  Created by Isa Melsov on 23/9/25.
//

import UIKit
import SwiftUI
import AVFoundation

final class CameraViewController: UIViewController, AVCapturePhotoCaptureDelegate {

    private let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "camera.session.queue", qos: .userInitiated)
    private let output = AVCapturePhotoOutput()
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private var videoDevice: AVCaptureDevice?
    private var input: AVCaptureDeviceInput?
    private var cachedOrientation: AVCaptureVideoOrientation = .portrait
    private var isConfigured = false
    
    private var isCapturing = false

    private let coordinator: BridgingCoordinator

    init(coordinator: BridgingCoordinator) {
        self.coordinator = coordinator
        super.init(nibName: nil, bundle: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        sessionQueue.sync {
            if self.session.isRunning { self.session.stopRunning() }
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)


    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        NotificationCenter.default.addObserver(self, selector: #selector(takePhotoAction),         name: .takePhoto, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(toggleTorchNote(_:)),     name: .toggleTorch, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(pauseCamera),             name: .pauseCamera, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(resumeCamera),            name: .resumeCamera, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(sessionWasInterrupted(_:)), name: .AVCaptureSessionWasInterrupted, object: session)
        NotificationCenter.default.addObserver(self, selector: #selector(sessionInterruptionEnded(_:)), name: .AVCaptureSessionInterruptionEnded, object: session)
        NotificationCenter.default.addObserver(self, selector: #selector(sessionRuntimeError(_:)), name: .AVCaptureSessionRuntimeError, object: session)

        ensureAuthorization { [weak self] granted in
            guard let self, granted else { return }
            self.sessionQueue.async {
                self.configureSessionIfNeeded()
                if !self.session.isRunning { self.session.startRunning() }
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)

        DispatchQueue.main.async {
            self.previewLayer.connection?.isEnabled = false
            self.previewLayer.isHidden = true
        }
        sessionQueue.async { [weak self] in
            guard let self else { return }
            if self.session.isRunning { self.session.stopRunning() }
        }
    }


    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer.frame = view.bounds
        updatePreviewOrientationAndCache()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to:size, with: coordinator)
        coordinator.animate(alongsideTransition: nil) { _ in
            self.updatePreviewOrientationAndCache()
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

            // ★ защита для iOS 16 — этот блок только с iOS 17 API
            if #available(iOS 17.0, *), let dev = self.videoDevice {
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
            guard self.session.isRunning, !self.isCapturing else { return }
            self.isCapturing = true

            if let conn = self.output.connection(with: .video),
               conn.isVideoOrientationSupported {
                conn.videoOrientation = self.cachedOrientation
            }

            let settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
            settings.photoQualityPrioritization = .speed
            self.output.capturePhoto(with: settings, delegate: self)
        }
    }

    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {
        defer { isCapturing = false }
        guard error == nil,
              let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else { return }

        sessionQueue.async {
            if self.session.isRunning { self.session.stopRunning() }

            DispatchQueue.main.async {
                self.previewLayer.connection?.isEnabled = false
                self.previewLayer.isHidden = true

                self.coordinator.capturedImage = image
            }
        }
    }


    // MARK: - Pause / Resume  ★

    @objc private func pauseCamera() {
        sessionQueue.async {
            if self.session.isRunning { self.session.stopRunning() }
            DispatchQueue.main.async {
                self.previewLayer.connection?.isEnabled = false
                self.previewLayer.isHidden = true
            }
        }
    }

    @objc private func resumeCamera() {
        let delay: DispatchTimeInterval = .milliseconds(150)
        sessionQueue.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self = self else { return }

            var canShowPreview = false
            DispatchQueue.main.sync {
                canShowPreview = self.isViewLoaded && (self.view.window != nil)
                if canShowPreview {
                    self.previewLayer.connection?.isEnabled = true
                    self.previewLayer.isHidden = false
                }
            }
            guard canShowPreview else { return }

            if !self.session.isRunning {
                self.session.startRunning()
            }
        }
    }



    // MARK: - Interruption / Errors

    @objc private func sessionWasInterrupted(_ note: Notification) {
    }

    @objc private func sessionInterruptionEnded(_ note: Notification) {
        resumeCamera()
    }

    @objc private func sessionRuntimeError(_ note: Notification) {
        sessionQueue.async {
            self.session.stopRunning()
            self.session.startRunning()
        }
    }

    // MARK: - Authorization  ★

    private func ensureAuthorization(_ completion: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            completion(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                completion(granted)
            }
        default:
            completion(false)
        }
    }
}



