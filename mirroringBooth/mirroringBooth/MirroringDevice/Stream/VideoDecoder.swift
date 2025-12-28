//
//  VideoDecoder.swift
//  mirroringBooth
//
//  Created by 이상유 on 2025-12-27.
//

import Foundation
import AVFoundation
import VideoToolbox

/// H.264 비디오 스트림 디코더
/// 수신된 패킷을 디코딩하여 화면에 표시 가능한 프레임으로 변환
final class VideoDecoder {

    /// 디코딩된 프레임을 전달하는 콜백
    var onDecodedFrame: ((CVPixelBuffer) -> Void)?

    /// 비디오 압축 해제 세션 (디코더)
    private var decompressionSession: VTDecompressionSession?

    /// SPS (Sequence Parameter Set) - 비디오 시퀀스 설정 정보
    private var spsData: Data?

    /// PPS (Picture Parameter Set) - 픽처 파라미터 정보
    private var ppsData: Data?

    /// 포맷 정보 (SPS/PPS로부터 생성)
    private var formatDescription: CMFormatDescription?

    /// 디코딩 결과 콜백
    private let decompressionOutputCallback: VTDecompressionOutputCallback = {
        decompressionOutputRefCon,
        sourceFrameRefCon,
        status,
        infoFlags,
        imageBuffer,
        presentationTimeStamp,
        presentationDuration in

        guard status == noErr,
              let imageBuffer
        else {
            print("Decoding failed with status: \(status)")
            return
        }

        let decoder = Unmanaged<VideoDecoder>
            .fromOpaque(decompressionOutputRefCon!)
            .takeUnretainedValue()

        decoder.onDecodedFrame?(imageBuffer)
    }

    // 수신된 비디오 패킷 처리
    func handleReceivedPacket(_ packetData: Data) {
        guard let packet = DataPacket.deserialize(packetData) else {
            return
        }

        switch packet.type {
        case .sps:
            handleSPS(packet.data)
        case .pps:
            handlePPS(packet.data)
        case .idrFrame, .pFrame:
            handleFrame(packet.data, isKeyFrame: packet.type == .idrFrame)
        default:
            break
        }
    }

    // SPS 데이터 처리
    private func handleSPS(_ data: Data) {
        spsData = data

        // SPS와 PPS가 모두 있으면 디코더 초기화
        if ppsData != nil {
            setupDecoder()
        }
    }

    // PPS 데이터 처리
    private func handlePPS(_ data: Data) {
        ppsData = data

        // SPS와 PPS가 모두 있으면 디코더 초기화
        if spsData != nil {
            setupDecoder()
        }
    }

    // SPS/PPS로부터 CMFormatDescription 생성 및 디코더 설정
    private func setupDecoder() {
        guard let sps = spsData,
              let pps = ppsData
        else { return }

        // SPS와 PPS로부터 포맷 정보 생성
        // withUnsafeBytes 내에서 모든 작업 수행 (포인터 생명주기 보장)
        let status = sps.withUnsafeBytes { spsBuffer -> OSStatus in
            pps.withUnsafeBytes { ppsBuffer -> OSStatus in
                guard let spsPtr = spsBuffer.baseAddress?.assumingMemoryBound(to: UInt8.self),
                      let ppsPtr = ppsBuffer.baseAddress?.assumingMemoryBound(to: UInt8.self) else {
                    return -1
                }

                let parameterSetPointers: [UnsafePointer<UInt8>] = [spsPtr, ppsPtr]
                let parameterSetSizes: [Int] = [sps.count, pps.count]

                return CMVideoFormatDescriptionCreateFromH264ParameterSets(
                    allocator: kCFAllocatorDefault,
                    parameterSetCount: 2,
                    parameterSetPointers: parameterSetPointers,
                    parameterSetSizes: parameterSetSizes,
                    nalUnitHeaderLength: 4,
                    formatDescriptionOut: &formatDescription
                )
            }
        }

        guard status == noErr,
              let formatDesc = formatDescription
        else { return }

        // 기존 세션이 있으면 무효화
        if let session = decompressionSession {
            VTDecompressionSessionInvalidate(session)
            decompressionSession = nil
        }

        // 디코더 세션 생성
        var videoDecoderSpecification: [CFString: Any] = [:]
        #if targetEnvironment(simulator)
        // 시뮬레이터에서는 소프트웨어 디코더 사용
        videoDecoderSpecification[kVTVideoDecoderSpecification_EnableHardwareAcceleratedVideoDecoder] = false
        #endif

        let destinationImageBufferAttributes: [CFString: Any] = [
            kCVPixelBufferPixelFormatTypeKey: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange,
            kCVPixelBufferMetalCompatibilityKey: true
        ]

        var callbackRecord = VTDecompressionOutputCallbackRecord(
            decompressionOutputCallback: decompressionOutputCallback,
            decompressionOutputRefCon: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        )

        var session: VTDecompressionSession?
        let createStatus = withUnsafePointer(to: &callbackRecord) { callbackPtr in
            VTDecompressionSessionCreate(
                allocator: kCFAllocatorDefault,
                formatDescription: formatDesc,
                decoderSpecification: videoDecoderSpecification as CFDictionary,
                imageBufferAttributes: destinationImageBufferAttributes as CFDictionary,
                outputCallback: callbackPtr,
                decompressionSessionOut: &session
            )
        }

        guard createStatus == noErr,
              let decoderSession = session
        else { return }

        decompressionSession = decoderSession
    }

    // 프레임 데이터 디코딩
    private func handleFrame(_ data: Data, isKeyFrame: Bool) {
        guard let session = decompressionSession else { return }

        // CMBlockBuffer 생성
        var blockBuffer: CMBlockBuffer?
        let dataPointer = (data as NSData).bytes.bindMemory(to: UInt8.self, capacity: data.count)

        let blockBufferStatus = CMBlockBufferCreateWithMemoryBlock(
            allocator: kCFAllocatorDefault,
            memoryBlock: nil,
            blockLength: data.count,
            blockAllocator: kCFAllocatorDefault,
            customBlockSource: nil,
            offsetToData: 0,
            dataLength: data.count,
            flags: 0,
            blockBufferOut: &blockBuffer
        )

        guard blockBufferStatus == noErr,
              let buffer = blockBuffer
        else {
            print("Failed to create block buffer: \(blockBufferStatus)")
            return
        }

        // 데이터 복사
        CMBlockBufferReplaceDataBytes(
            with: dataPointer,
            blockBuffer: buffer,
            offsetIntoDestination: 0,
            dataLength: data.count
        )

        // CMSampleBuffer 생성
        var sampleBuffer: CMSampleBuffer?
        var sampleSizeArray = [data.count]

        let sampleBufferStatus = CMSampleBufferCreateReady(
            allocator: kCFAllocatorDefault,
            dataBuffer: buffer,
            formatDescription: formatDescription,
            sampleCount: 1,
            sampleTimingEntryCount: 0,
            sampleTimingArray: nil,
            sampleSizeEntryCount: 1,
            sampleSizeArray: &sampleSizeArray,
            sampleBufferOut: &sampleBuffer
        )

        guard sampleBufferStatus == noErr,
              let sample = sampleBuffer
        else {
            print("Failed to create sample buffer: \(sampleBufferStatus)")
            return
        }

        // 프레임 디코딩
        var infoFlags = VTDecodeInfoFlags()
        VTDecompressionSessionDecodeFrame(
            session,
            sampleBuffer: sample,
            flags: [._EnableAsynchronousDecompression],
            frameRefcon: nil,
            infoFlagsOut: &infoFlags
        )
    }

    // 디코더 세션 정리
    func cleanup() {
        if let session = decompressionSession {
            VTDecompressionSessionInvalidate(session)
            decompressionSession = nil
        }

        spsData = nil
        ppsData = nil
        formatDescription = nil
    }

    deinit {
        cleanup()
    }
    
}
