//
//  CameraManager.swift
//  mirroringBooth
//
//  Created by 윤대현 on 1/2/26.
//

import AVFoundation
import Observation
import OSLog
import UIKit

final class CameraManager: NSObject {
    private let logger = Logger.cameraManager

    let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "session.queue")

    private var videoDevice: AVCaptureDevice?
    private var videoInput: AVCaptureDeviceInput?
    private var videoOutput: AVCaptureVideoDataOutput?
    private var photoOutput = AVCapturePhotoOutput()

    private let encoder = H264Encoder(resolution: .photo)

    /// 원시 데이터 콜백
    var rawData: ((CMSampleBuffer) -> Void)?

    /// 인코딩된 데이터 콜백
    var onEncodedData: ((Data) -> Void)? {
        get { encoder.onEncodedData }
        set { encoder.onEncodedData = newValue }
    }

    /// 촬영된 이미지 데이터 콜백
    var onCapturedPhoto: ((Data) -> Void)?

    /// 전송 완료 콜백
    var onTransferCompleted: (() -> Void)?

    /// 10장 저장 완료 콜백 (타이머 모드에서 10장 모두 저장되면 호출)
    var onAllPhotosStored: ((Int) -> Void)?

    // 촬영된 이미지 임시 저장 배열
    private var capturedPhotos: [Data] = []

    // 현재 전송 진행 상황
    var transferProgress: (current: Int, total: Int) = (0, 0)

    /// Session을 시작합니다.
    func startSession() {
        // 권한을 확인합니다.
        AVCaptureDevice.requestAccess(for: .video) { [weak self] hasPermission in
            guard let self, hasPermission else {
                self?.logger.warning("카메라 권한이 거부되었습니다.")
                return
            }

            // 인코더를 실행합니다.
            self.encoder.start()

            // 세션을 설정하고 시작합니다.
            self.sessionQueue.async {
                self.setupSession()
                self.session.startRunning()
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
    func capturePhoto(_ orientation: CameraOrientation) {
        DispatchQueue.main.async {
            self.logger.info("capturePhoto() 호출됨 - 촬영 시작")
            // JPEG 포맷으로 사진 촬영
            let settings = AVCapturePhotoSettings(
                format: [AVVideoCodecKey: AVVideoCodecType.jpeg]
            )

            if let photoConnection = self.photoOutput.connection(with: .video) {
                let rotationAngle = orientation.rotationAngle

                if photoConnection.isVideoRotationAngleSupported(rotationAngle) {
                    photoConnection.videoRotationAngle = rotationAngle
                }
            }

            self.photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }

    /// 저장된 사진을 일괄 전송합니다.
    func sendAllPhotos(using browser: Browser) {
        let total = capturedPhotos.count
        guard total > 0 else {
            logger.warning("전송할 사진이 없습니다.")
            return
        }

        transferProgress = (0, total)
        logger.info("일괄 전송 시작: \(total)장")

        Task { @MainActor in
            for (index, photoData) in capturedPhotos.enumerated() {
                browser.sendPhotoResource(photoData)

                transferProgress = (index + 1, total)

                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1초 짧게 대기
            }

            // 전송 완료 처리
            capturedPhotos.removeAll()
            transferProgress = (0, 0)
            logger.info("일괄 전송 완료")
            onTransferCompleted?()
        }
    }
}

// MARK: - Private 메서드
extension CameraManager {
    private func setupSession() {
        session.beginConfiguration()
        defer { session.commitConfiguration() }

        session.sessionPreset = .inputPriority

        guard let videoDevice = AVCaptureDevice.default(
            .builtInWideAngleCamera,
            for: .video,
            position: .back
        ) else {
            return
        }

        self.videoDevice = videoDevice

        self.applyActiveFormat(
            videoDevice: videoDevice,
            targetWidth: 1920,
            targetHeight: 1440
        )

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
        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange
        ]

        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
            self.videoOutput = videoOutput

            // 비디오 방향을 세로로 설정합니다.
            if let connection = videoOutput.connection(with: .video),
               connection.isVideoRotationAngleSupported(90) {
                connection.videoRotationAngle = 90
            }
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

    private func applyActiveFormat(
        videoDevice: AVCaptureDevice,
        targetWidth: Int32,
        targetHeight: Int32
    ) {
        let formats = videoDevice.formats
        let bestFormat = formats.first(where: { (format: AVCaptureDevice.Format) -> Bool in
            // 해상도 + 420 포맷 체크
            let dimensions = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
            guard dimensions.width == targetWidth && dimensions.height == targetHeight else { return false }

            let mediaSubTypeValue = CMFormatDescriptionGetMediaSubType(format.formatDescription)
            return mediaSubTypeValue == kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
        }) ?? formats.first(where: { (format: AVCaptureDevice.Format) -> Bool in
            // 해상도만 체크
            let dimensions = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
            return dimensions.width == targetWidth && dimensions.height == targetHeight
        })

        guard let bestFormat: AVCaptureDevice.Format = bestFormat else {
            logger.warning("요청한 해상도 포맷을 찾지 못했습니다. \(targetWidth)x\(targetHeight)")
            return
        }

        do {
            try videoDevice.lockForConfiguration()
            videoDevice.activeFormat = bestFormat
            videoDevice.unlockForConfiguration()
            logger.info("카메라 포맷(\(targetWidth)x\(targetHeight))이 성공적으로 적용되었습니다.")
        } catch {
            logger.warning("카메라 포맷(\(targetWidth)x\(targetHeight)) 적용에 실패했습니다. \(error)")
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
        rawData?(sampleBuffer)
        encoder.encode(sampleBuffer)
    }

    func captureOutput(
        _ output: AVCaptureOutput,
        didDrop sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        // 프레임 드롭 발생
    }
}

// MARK: - Photo Capture Delegate
extension CameraManager: AVCapturePhotoCaptureDelegate {

    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        guard error == nil, let imageData = photo.fileDataRepresentation() else { return }

        sessionQueue.async { [weak self] in
            guard let self else { return }

            guard let uiImage = UIImage(data: imageData) else {
                self.storePhotoData(imageData)
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

            guard let resizedImage = self.resizeImage(uiImage, to: targetSize),
                  let compressedData = resizedImage.jpegData(compressionQuality: 0.6) else {
                // 리사이즈 실패 시 원본 사용
                self.storePhotoData(imageData)
                return
            }

            self.storePhotoData(compressedData)
        }
    }

    /// 촬영된 사진 데이터를 저장하고 콜백을 호출합니다.
    private func storePhotoData(_ photoData: Data) {
        DispatchQueue.main.async {
            self.capturedPhotos.append(photoData)
            let storedCount = self.capturedPhotos.count

            // 수동 촬영 버튼용 콜백
            // self.onCapturedPhoto?(photoData)

            // 10장 모두 저장되면 콜백 호출
            if storedCount == 10 {
                self.onAllPhotosStored?(storedCount)
            }
        }
    }

    private func resizeImage(_ image: UIImage, to targetSize: CGSize) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
}
