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
    private let logger = AppLogger.make(for: H264Encoder.self)
    private let encoderQueue = DispatchQueue(label: "encoder.queue")
    
    private var compressionSession: VTCompressionSession?
    private let width: Int32
    private let height: Int32
    private let bitRate: Int
    private let frameRate: Int
    
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
    
    func encode(_ sampleBuffer: CMSampleBuffer) -> Data? {
        // TODO: 인코딩은 추후
        return nil
    }
}

// MARK: - Private
extension H264Encoder {
    private func setupCompressionSession() {
        var session: VTCompressionSession?
        
        let status = VTCompressionSessionCreate(
            allocator: kCFAllocatorDefault,
            width: width,
            height: height,
            codecType: kCMVideoCodecType_H264, // H264 설정
            encoderSpecification: nil,
            imageBufferAttributes: nil,
            compressedDataAllocator: nil,
            outputCallback: nil,
            refcon: nil,
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

