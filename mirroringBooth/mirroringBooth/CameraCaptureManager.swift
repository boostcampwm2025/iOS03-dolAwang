//
//  CameraCaptureManager.swift
//  mirroringBooth
//
//  Created by 최윤진 on 12/21/25.
//

import AVFoundation
import CoreImage

final class CameraCaptureManager: NSObject {
    typealias PixelBufferHandler = (_ pixelBuffer: CVPixelBuffer) -> Void
    private let captureQueue = DispatchQueue(label: "camera.captureQueue")
    private let outputQueue = DispatchQueue(label: "camera.outputQueue")
    private var captureSession: AVCaptureSession?
    private var videoDataOutput: AVCaptureVideoDataOutput?
    private var currentCIImage: CIImage?
    var latestCIImage: CIImage? {
        outputQueue.sync { self.currentCIImage }
    }

    override init() {
        super.init()
        self.configureSession()
    }

    func startCapture() {
        self.captureQueue.async { [weak self] in
            guard let self = self else { return }
            if self.captureSession == nil {
                self.configureSession()
            }
            self.captureSession?.startRunning()
        }
    }

    func stopCapture() {
        self.captureQueue.async { [weak self] in
            guard let self = self else { return }
            self.captureSession?.stopRunning()

            self.outputQueue.async { [weak self] in
                guard let self = self else { return }
                self.currentCIImage = nil
            }
        }
    }
    private func configureSession() {
        let session = AVCaptureSession()
        session.beginConfiguration()
        session.sessionPreset = .high

        guard let captureDevice = AVCaptureDevice.default(
            .builtInWideAngleCamera, for: .video, position: .back) else {
            session.commitConfiguration()
            captureSession = session
            return
        }

        do {
            let deviceInput = try AVCaptureDeviceInput(device: captureDevice)
            if session.canAddInput(deviceInput) {
                session.addInput(deviceInput)
            }
        } catch {
            session.commitConfiguration()
            captureSession = session
            return
        }

        let output = AVCaptureVideoDataOutput()
        output.alwaysDiscardsLateVideoFrames = true
        output.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)
        ]
        output.setSampleBufferDelegate(self, queue: self.outputQueue)

        if session.canAddOutput(output) {
            session.addOutput(output)
        }

        if let connection = output.connection(with: .video) {
            connection.videoRotationAngle = 90
            if connection.isVideoMirroringSupported {
                connection.isVideoMirrored = false
            }
        }

        session.commitConfiguration()

        self.captureSession = session
        videoDataOutput = output
    }
}

extension CameraCaptureManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        self.outputQueue.async { [weak self] in
            guard let self = self else { return }
            self.currentCIImage = CIImage(cvPixelBuffer: pixelBuffer)
        }
    }
}
