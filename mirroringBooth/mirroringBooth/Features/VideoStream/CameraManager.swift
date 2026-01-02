//
//  CameraManager.swift
//  mirroringBooth
//
//  Created by 윤대현 on 1/2/26.
//

import Observation
import AVFoundation
import os

@Observable
final class CameraManager: NSObject {
    private let logger = AppLogger.make(for: CameraManager.self)

    let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "session.queue")

    private var videoDevice: AVCaptureDevice?
    private var videoInput: AVCaptureDeviceInput?
    private var videoOutput: AVCaptureVideoDataOutput?

    private let encoder = H264Encoder()

    /// 인코딩된 데이터 콜백
    var onEncodedData: ((Data) -> Void)? {
        get { encoder.onEncodedData }
        set { encoder.onEncodedData = newValue }
    }

    /// Session을 시작합니다.
    func startSession() async {
        // 권한을 확인합니다.
        let hasPermission = await AVCaptureDevice.requestAccess(for: .video)
        guard hasPermission else {
            logger.warning("카메라 권한이 거부되었습니다.")
            return
        }

        // 인코더를 실행합니다.
        encoder.start()

        // 세션을 설정하고 시작합니다.
        await withCheckedContinuation { continuation in
            sessionQueue.async { [weak self] in
                guard let self else {
                    continuation.resume()
                    return
                }

                self.setupSession()
                self.session.startRunning()

                continuation.resume()
            }
        }
    }

    /// Session을 멈춥니다.
    func stopSession() {
        encoder.stop()
        sessionQueue.async { [weak self] in
            self?.session.stopRunning()
        }
    }
}

// MARK: - Private 메서드
extension CameraManager {
    private func setupSession() {
        session.beginConfiguration()
        defer { session.commitConfiguration() }

        session.sessionPreset = .high // high를 기본값으로 두었습니다.

        guard let videoDevice = AVCaptureDevice.default(
            .builtInWideAngleCamera,
            for: .video,
            position: .back // 추후 전면 카메라 적용도 진행해보기
        ) else {
            return
        }

        self.videoDevice = videoDevice

        // 입력 추가
        do {
            let videoInput = try AVCaptureDeviceInput(device: videoDevice)
            if session.canAddInput(videoInput) {
                session.addInput(videoInput)
                self.videoInput = videoInput
            }
        } catch {
            logger.warning("카메라 입력 설정에 실패했습니다. \(error)")
            return
        }

        // 출력 추가 (프레임 캡처용)
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: sessionQueue)
        // YUV 포맷으로 설정했습니다.
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange]

        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
            self.videoOutput = videoOutput
        } else {
            logger.warning("비디오 출력 추가에 실패했습니다.")
        }
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        // 프레임 캡처 성공
        encoder.encode(sampleBuffer)
    }
    
    func captureOutput(
        _ output: AVCaptureOutput,
        didDrop sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        logger.warning("프레임 드롭 발생")
    }
}
