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
    /// SPS/PPS 전송 여부 플래그
    private var hasSentParameterSets = false
    
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

        // 카메라 세션은 백그라운드 스레드에서 시작
        // 메인 스레드에서 시작하면 UI 응답성 저하 가능
        cameraQueue.async { [weak self] in
            self?.session.startRunning()
        }
    }
    
    // 카메라 캡처 세션 중지
    func stopSession() {
        // 카메라 세션 중지도 백그라운드 스레드에서 수행
        cameraQueue.async { [weak self] in
            guard let self else { return }
            self.session.stopRunning()

            if let encoder = self.compressingSession {
                VTCompressionSessionCompleteFrames(encoder, untilPresentationTimeStamp: .invalid)
                VTCompressionSessionInvalidate(encoder)
                self.compressingSession = nil
            }

            self.hasSentParameterSets = false
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
        
        // 비트레이트 설정 (2 Mbps)
        VTSessionSetProperty(
            session,
            key: kVTCompressionPropertyKey_AverageBitRate,
            value: 2_000_000 as CFTypeRef
        )
        
        // 데이터 레이트 제한 설정
        VTSessionSetProperty(
            session,
            key: kVTCompressionPropertyKey_DataRateLimits,
            value: [2_500_000, 1] as CFArray
        )
        
        VTCompressionSessionPrepareToEncodeFrames(session)
    }
    
    // 인코딩 된 데이터 처리
    private func handleEncodedSampleBuffer(_ sampleBuffer: CMSampleBuffer) {
        guard let dataBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) else { return }

        // 1. KeyFrame 여부 확인
        let isKeyFrame = checkIfKeyFrame(sampleBuffer)

        // 2. KeyFrame이고 아직 SPS/PPS를 전송하지 않았다면 전송
        if isKeyFrame, !hasSentParameterSets {
            /// formatDescription: 비디오 포맷 정보
            if let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer) {
                sendParameterSets(formatDescription)
                hasSentParameterSets = true
            }
        }

        // 3. 프레임 데이터 추출
        var length: Int = 0
        var dataPointer: UnsafeMutablePointer<Int8>?
        
        CMBlockBufferGetDataPointer(
            dataBuffer,
            atOffset: 0,
            lengthAtOffsetOut: nil,
            totalLengthOut: &length,
            dataPointerOut: &dataPointer
        )

        guard let pointer = dataPointer else { return }
        let frameData = Data(bytes: pointer, count: length)

        // 4. 프레임 타입에 따라 패킷 생성 및 전송
        let packetType: VideoPacketType = isKeyFrame ? .idrFrame : .pFrame
        let packet = VideoPacket(type: packetType, data: frameData)

        onEncodedFrame?(packet.serialize())
    }
    
    // KeyFrame(IDR Frame) 여부 확인
    private func checkIfKeyFrame(_ sampleBuffer: CMSampleBuffer) -> Bool {
        guard let attachments = CMSampleBufferGetSampleAttachmentsArray(
            sampleBuffer,
            createIfNecessary: false
        ) as? [[CFString: Any]],
              let attachment = attachments.first
        else { return false }

        // NotSync가 false이면 KeyFrame(Sync Frame)
        let notSync = attachment[kCMSampleAttachmentKey_NotSync] as? Bool ?? false
        return !notSync
    }
    
    // SPS/PPS 파라미터 셋 추출 및 전송
    private func sendParameterSets(_ formatDescription: CMFormatDescription) {
        var spsSize: Int = 0
        var spsCount: Int = 0
        var ppsSize: Int = 0
        var ppsCount: Int = 0
        var sps: UnsafePointer<UInt8>?
        var pps: UnsafePointer<UInt8>?

        // SPS 추출 (index 0)
        let spsStatus = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(
            formatDescription,
            parameterSetIndex: 0,
            parameterSetPointerOut: &sps,
            parameterSetSizeOut: &spsSize,
            parameterSetCountOut: &spsCount,
            nalUnitHeaderLengthOut: nil
        )

        // PPS 추출 (index 1)
        let ppsStatus = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(
            formatDescription,
            parameterSetIndex: 1,
            parameterSetPointerOut: &pps,
            parameterSetSizeOut: &ppsSize,
            parameterSetCountOut: &ppsCount,
            nalUnitHeaderLengthOut: nil
        )

        // SPS/PPS 전송
        guard spsStatus == noErr,
              ppsStatus == noErr,
              let spsPointer = sps,
              let ppsPointer = pps
        else {
            print("Failed to extract SPS/PPS")
            return
        }

        // SPS 패킷 생성 및 전송
        let spsData = Data(bytes: spsPointer, count: spsSize)
        let spsPacket = VideoPacket(type: .sps, data: spsData)
        onEncodedFrame?(spsPacket.serialize())

        // PPS 패킷 생성 및 전송
        let ppsData = Data(bytes: ppsPointer, count: ppsSize)
        let ppsPacket = VideoPacket(type: .pps, data: ppsData)
        onEncodedFrame?(ppsPacket.serialize())
    }
    
}
