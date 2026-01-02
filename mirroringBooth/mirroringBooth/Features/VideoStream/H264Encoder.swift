//
//  H264Encoder.swift
//  mirroringBooth
//
//  Created by 윤대현 on 1/2/26.
//

import CoreMedia
import Foundation
import Observation
import VideoToolbox
import os

@Observable
final class H264Encoder: VideoEncoder {
    let logger = AppLogger.make(for: H264Encoder.self)
    private let encoderQueue = DispatchQueue(label: "encoder.queue")
    
    private var compressionSession: VTCompressionSession?
    private let width: Int32
    private let height: Int32
    private let bitRate: Int
    private let frameRate: Int
    
    /// 인코딩된 데이터를 받는 콜백
    var onEncodedData: ((Data) -> Void)?
    
    init(
        resolution: VideoStreamSettings.Resolution = VideoStreamSettings.defaultResolution,
        bitRate: VideoStreamSettings.BitRate = VideoStreamSettings.defaultBitRate,
        frameRate: VideoStreamSettings.FrameRate = VideoStreamSettings.defaultFrameRate
    ) {
        self.width = resolution.width
        self.height = resolution.height
        self.bitRate = bitRate.value
        self.frameRate = frameRate.value
    }
    
    func start() {
        encoderQueue.async { [weak self] in
            self?.setupCompressionSession()
        }
    }
    
    func stop() {
        encoderQueue.async { [weak self] in
            guard let session = self?.compressionSession else { return }
            VTCompressionSessionCompleteFrames(session, untilPresentationTimeStamp: .invalid)
            VTCompressionSessionInvalidate(session)
            self?.compressionSession = nil
        }
    }
    
    func encode(_ sampleBuffer: CMSampleBuffer) {
        guard let session = compressionSession else {
            logger.warning("인코딩 세션이 준비되지 않았습니다.")
            return
        }
        
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            logger.warning("CMSampleBuffer에서 ImageBuffer를 가져올 수 없습니다.")
            return
        }
        
        let presentationTimeStamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        let duration = CMSampleBufferGetDuration(sampleBuffer)
        
        encoderQueue.async { [weak self] in
            let status = VTCompressionSessionEncodeFrame(
                session,
                imageBuffer: imageBuffer,
                presentationTimeStamp: presentationTimeStamp,
                duration: duration,
                frameProperties: nil,
                sourceFrameRefcon: nil,
                infoFlagsOut: nil
            )
            
            if status != noErr {
                self?.logger.warning("프레임 인코딩 실패: \(status)")
            }
        }
    }

    func handleEncodedData(_ sampleBuffer: CMSampleBuffer) {
        // TODO: NAL units 추출 및 onEncodedData 콜백 호출
    }
}

// MARK: - Private
extension H264Encoder {
    private func setupCompressionSession() {
        var session: VTCompressionSession?
        
        // 콜백용 self 포인터 준비
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        
        let status = VTCompressionSessionCreate(
            allocator: kCFAllocatorDefault,
            width: width,
            height: height,
            codecType: kCMVideoCodecType_H264, // H264 설정
            encoderSpecification: nil,
            imageBufferAttributes: nil,
            compressedDataAllocator: nil,
            outputCallback: compressionOutputCallback,
            refcon: selfPtr,
            compressionSessionOut: &session
        )
        
        guard status == noErr, let compressionSession = session else {
            logger.error("VTCompressionSession 생성 실패: \(status)")
            return
        }
        
        // 인코딩 설정
        configureSession(compressionSession)
        
        // 세션 준비
        let prepareStatus = VTCompressionSessionPrepareToEncodeFrames(compressionSession)
        guard prepareStatus == noErr else {
            logger.error("세션 준비 실패: \(prepareStatus)")
            return
        }
        
        self.compressionSession = compressionSession
        logger.info("H.264 인코딩 세션 생성 완료")
    }
    
    private func configureSession(_ session: VTCompressionSession) {
        // 실시간 인코딩 설정
        VTSessionSetProperty(session, key: kVTCompressionPropertyKey_RealTime, value: kCFBooleanTrue)
        
        // 프레임 레이트
        VTSessionSetProperty(session, key: kVTCompressionPropertyKey_ExpectedFrameRate, value: NSNumber(value: frameRate))
        
        // 비트레이트
        VTSessionSetProperty(session, key: kVTCompressionPropertyKey_AverageBitRate, value: NSNumber(value: bitRate))
        
        // 프로파일 (Baseline)
        VTSessionSetProperty(session, key: kVTCompressionPropertyKey_ProfileLevel, value: kVTProfileLevel_H264_Baseline_AutoLevel)
        
        // B-frame 제거 (지연을 최소화하기 위해 B 프레임은 제거해보았습니다.)
        VTSessionSetProperty(session, key: kVTCompressionPropertyKey_AllowFrameReordering, value: kCFBooleanFalse)
        
        // 키프레임 간격 (1초당 1개)
        VTSessionSetProperty(session, key: kVTCompressionPropertyKey_MaxKeyFrameInterval, value: NSNumber(value: frameRate))
    }
}

// MARK: - Compression Output Callback
private func compressionOutputCallback(
    outputCallbackRefCon: UnsafeMutableRawPointer?,
    sourceFrameRefCon: UnsafeMutableRawPointer?,
    status: OSStatus,
    infoFlags: VTEncodeInfoFlags,
    sampleBuffer: CMSampleBuffer?
) {
    guard let refcon = outputCallbackRefCon else { return }
    let encoder = Unmanaged<H264Encoder>.fromOpaque(refcon).takeUnretainedValue()

    guard status == noErr, let sampleBuffer = sampleBuffer else {
        encoder.logger.warning("인코딩 실패 또는 sampleBuffer 없음: \(status)")
        return
    }

    encoder.handleEncodedData(sampleBuffer)
}
