//
//  LiveVideoSource.swift
//  mirroringBooth
//
//  Created by 이상유 on 2025-12-27.
//

import Foundation
import AVFoundation
import VideoToolbox

final class LiveVideoSource: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    var onEncodedFrame: ((Data) -> Void)?
    
    /// 카메라 캡처 세션
    private let session = AVCaptureSession()
    private let cameraQueue = DispatchQueue(label: "cameraQueue")
    /// 비디오 압축 세션(인코더)
    private var compressingSession: VTCompressionSession?
    
    /// 인코딩 결과 콜백
    private let compressionOutputCallback: VTCompressionOutputCallback = {
        outputCallbackRefCon,
        sourceFrameRefCon,
        status,
        infoFlags,
        sampleBuffer in
        
        guard status == noErr,
              let sampleBuffer,
              CMSampleBufferDataIsReady(sampleBuffer)
        else { return }
        
        let manager = Unmanaged<LiveVideoSource>
            .fromOpaque(outputCallbackRefCon!)
            .takeUnretainedValue()
        
        manager.handleEncodedSampleBuffer(sampleBuffer)
    }
    
    // 카메라 캡처 세션 설정 및 시작
    func startSession() throws {
        session.sessionPreset = .hd1280x720
        
        guard let device = AVCaptureDevice.default(
            .builtInWideAngleCamera,
            for: .video,
            position: .back
        ) else { return }
        
        let input = try AVCaptureDeviceInput(device: device)
        
        if session.canAddInput(input) {
            session.addInput(input)
        }
        
        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: cameraQueue)
        output.alwaysDiscardsLateVideoFrames = true
        
        if session.canAddOutput(output) {
            session.addOutput(output)
        }
        
        session.startRunning()
    }
    
    // 카메라 캡처 세션 중지
    func stopSession() {
        session.stopRunning()
        
        if let encoder = compressingSession {
            VTCompressionSessionCompleteFrames(encoder, untilPresentationTimeStamp: .invalid)
            VTCompressionSessionInvalidate(encoder)
            compressingSession = nil
        }
    }
    
}

// MARK: - encode

extension LiveVideoSource {
    
    // 프레임 처리 -> 인코딩 시작
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        if compressingSession == nil {
            if let format = CMSampleBufferGetFormatDescription(sampleBuffer) {
                let dimensions = CMVideoFormatDescriptionGetDimensions(format)
                setupVideoEncoder(width: dimensions.width, height: dimensions.height)
            }
        }
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer),
              let session = compressingSession
        else { return }
        
        let pts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        
        VTCompressionSessionEncodeFrame(
            session,
            imageBuffer: pixelBuffer,
            presentationTimeStamp: pts,
            duration: .invalid,
            frameProperties: nil,
            sourceFrameRefcon: nil,
            infoFlagsOut: nil
        )
    }
    
    // 비디오 압축 세션(인코더) 설정
    private func setupVideoEncoder(width: Int32, height: Int32) {
        VTCompressionSessionCreate(
            allocator: nil,
            width: width,
            height: height,
            codecType: kCMVideoCodecType_H264,
            encoderSpecification: nil,
            imageBufferAttributes: nil,
            compressedDataAllocator: nil,
            outputCallback: compressionOutputCallback,
            refcon: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()),
            compressionSessionOut: &compressingSession
        )
        
        guard let session = compressingSession else { return }
        
        // 실시간 인코딩 모드 활성화
        // 낮은 레이턴시를 위해 프레임 버퍼링을 최소화하고 즉시 인코딩
        VTSessionSetProperty(
            session,
            key: kVTCompressionPropertyKey_RealTime,
            value: kCFBooleanTrue
        )
        
        // H.264 Baseline Profile 사용
        // 가장 넓은 호환성을 제공하며, 대부분의 디바이스에서 디코딩 가능
        // AutoLevel: 해상도와 비트레이트에 따라 자동으로 레벨 선택
        VTSessionSetProperty(
            session,
            key: kVTCompressionPropertyKey_ProfileLevel,
            value: kVTProfileLevel_H264_Baseline_AutoLevel
        )
        
        // KeyFrame 간격 설정 (30프레임마다 KeyFrame 생성)
        // KeyFrame은 독립적으로 디코딩 가능하여 스트림 중간 진입점 제공
        // 값이 작을수록 빠른 복구 가능, 크면 압축률 향상
        VTSessionSetProperty(
            session,
            key: kVTCompressionPropertyKey_MaxKeyFrameInterval,
            value: 30 as CFTypeRef
        )
        
        VTCompressionSessionPrepareToEncodeFrames(session)
    }
    
    // 인코딩 된 데이터 처리
    private func handleEncodedSampleBuffer(_ sampleBuffer: CMSampleBuffer) {
        guard let dataBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) else { return }
        
        var length: Int = 0
        var dataPointer: UnsafeMutablePointer<Int8>?
        
        CMBlockBufferGetDataPointer(
            dataBuffer,
            atOffset: 0,
            lengthAtOffsetOut: nil,
            totalLengthOut: &length,
            dataPointerOut: &dataPointer
        )
        
        let data = Data(bytes: dataPointer!, count: length)
        onEncodedFrame?(data)
    }
    
}
