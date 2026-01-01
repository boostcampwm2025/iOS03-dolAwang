//
//  CameraManager.swift
//  mirroringBooth
//
//  Created by Liam on 12/31/25.
//

import AVFoundation

@Observable
final class CameraManager: NSObject {
    let session = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let videoQueue = DispatchQueue(label: "com.review.videoQueue")
    private let h264Encoder = H264Encoder()
    private var videoDataHandler: ((Data) -> Void)? = nil
    
    override init() {
        super.init()
        h264Encoder.delegate = self
        checkPermission()
    }
    
    func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            self.setupSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted { self?.setupSession() }
                }
            }
        default:
            break
        }
    }
    
    func configure(videoDataHandler: ((Data) -> Void)?) {
        self.videoDataHandler = videoDataHandler
    }
    
    private func setupSession() {
        session.beginConfiguration()
        
        // 화질 설정
        if session.canSetSessionPreset(.hd1920x1080) {
            session.sessionPreset = .hd1920x1080
        }
        h264Encoder.configure(width: 1920, height: 1080)
        
        //입력 장치 연결
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice) else {
            return
        }
        if session.canAddInput(videoInput) {
            session.addInput(videoInput)
        }
        
        // 출력 장치 연결
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
            // 딜레이 프레임 제거
            videoOutput.alwaysDiscardsLateVideoFrames = true
            // 델리게이트 연결
            videoOutput.setSampleBufferDelegate(self, queue: videoQueue)
        }
        
        // 세션 시작 (백그라운드에서 실행해야 함)
        session.commitConfiguration()
        DispatchQueue.global(qos: .userInitiated).async {
            self.session.startRunning()
        }
    }
}

extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate, H264EncoderDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        h264Encoder.encode(sampleBuffer: sampleBuffer)
    }
    
    func videoEncoder(_ encoder: H264Encoder, didEncode data: Data) {
        videoDataHandler?(data)
    }
}
