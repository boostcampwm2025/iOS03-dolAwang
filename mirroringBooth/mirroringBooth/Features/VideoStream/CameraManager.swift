//
//  CameraManager.swift
//  mirroringBooth
//
//  Created by 윤대현 on 1/2/26.
//

import Observation
import AVFoundation
import UIKit
import os

@Observable
final class CameraManager: NSObject {
    private let logger = AppLogger.make(for: CameraManager.self)

    let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "session.queue")

    private var videoDevice: AVCaptureDevice?
    private var videoInput: AVCaptureDeviceInput?
    private var videoOutput: AVCaptureVideoDataOutput?
    private var photoOutput: AVCapturePhotoOutput?

    private let encoder = H264Encoder()
    
    /// 사진 촬영 delegate (촬영 완료 전까지 유지)
    private var photoCaptureDelegate: PhotoCaptureDelegate?

    /// 인코딩된 데이터 콜백
    var onEncodedData: ((Data) -> Void)? {
        get { encoder.onEncodedData }
        set { encoder.onEncodedData = newValue }
    }
    
    /// 촬영된 이미지 데이터 콜백
    var onCapturedPhoto: ((Data) -> Void)?

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
    
    /// 사진을 촬영합니다.
    func capturePhoto() {
        sessionQueue.async { [weak self] in
            guard let self,
                  let photoOutput = self.photoOutput else {
                self?.logger.warning("사진 촬영 준비가 되지 않았습니다.")
                return
            }

            // JPEG 포맷으로 사진 촬영
            let settings = AVCapturePhotoSettings(
                format: [AVVideoCodecKey: AVVideoCodecType.jpeg]
            )

            self.photoCaptureDelegate = PhotoCaptureDelegate { [weak self] imageData in
                self?.onCapturedPhoto?(imageData)
                self?.photoCaptureDelegate = nil // 촬영 완료 후 해제
            }

            photoOutput.capturePhoto(with: settings, delegate: self.photoCaptureDelegate!)
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
        
        // 사진 출력 추가
        let photoOutput = AVCapturePhotoOutput()
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
            self.photoOutput = photoOutput
        } else {
            logger.warning("사진 출력 추가에 실패했습니다.")
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

// MARK: - Photo Capture Delegate
private class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    private let completion: @Sendable (Data) -> Void
    
    init(completion: @escaping @Sendable (Data) -> Void) {
        self.completion = completion
        super.init()
    }

    // AVCapturePhotoCaptureDelegate에서 자꾸 @MainActor 경고가 발생하여 임시적으로 nonisolated로 지정했습니다.
    // 개선 예정입니다..
    nonisolated func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        guard error == nil,
              let imageData = photo.fileDataRepresentation() else {
            return
        }
        
        // 이미지 리사이즈 및 JPEG 압축 (최대 1920x1440 해상도, 품질 0.9)
        guard let uiImage = UIImage(data: imageData) else {
            completion(imageData)
            return
        }
        
        // 원본 이미지 크기 확인
        let originalSize = uiImage.size
        let maxSize = CGSize(width: 1920, height: 1440)
        
        // 원본이 더 작으면 리사이즈하지 않음
        let targetSize: CGSize
        if originalSize.width <= maxSize.width && originalSize.height <= maxSize.height {
            targetSize = originalSize
        } else {
            // 비율 유지하며 리사이즈
            let aspectRatio = originalSize.width / originalSize.height
            if aspectRatio > maxSize.width / maxSize.height {
                targetSize = CGSize(width: maxSize.width, height: maxSize.width / aspectRatio)
            } else {
                targetSize = CGSize(width: maxSize.height * aspectRatio, height: maxSize.height)
            }
        }
        
        guard let resizedImage = resizeImage(uiImage, to: targetSize),
              let compressedData = resizedImage.jpegData(compressionQuality: 0.9) else {
            completion(imageData) // 리사이즈 실패 시 원본 반환
            return
        }
        
        completion(compressedData)
    }
    
    nonisolated private func resizeImage(_ image: UIImage, to targetSize: CGSize) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
}
