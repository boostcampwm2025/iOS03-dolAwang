//
//  H264Decoder.swift
//  mirroringBooth
//
//  Created by 윤대현 on 1/2/26.
//

import CoreMedia
import Foundation
import Observation
import VideoToolbox
import QuartzCore
import os

@Observable
final class H264Decoder: VideoDecoder {
    let logger = AppLogger.make(for: H264Decoder.self)
    private let decoderQueue = DispatchQueue(label: "decoder.queue")

    private var decompressionSession: VTDecompressionSession?
    private var formatDescription: CMVideoFormatDescription?

    /// 디코딩된 샘플 버퍼를 받는 콜백
    var onDecodedSampleBuffer: ((CMSampleBuffer) -> Void)?

    // SPS/PPS 저장
    private var sps: Data?
    private var pps: Data?

    func start() {
    }

    func stop() {
        decoderQueue.async { [weak self] in
            if let session = self?.decompressionSession {
                VTDecompressionSessionInvalidate(session)
                self?.decompressionSession = nil
            }
            self?.formatDescription = nil
            self?.sps = nil
            self?.pps = nil
        }
    }

    func decode(_ data: Data) {
        decoderQueue.async { [weak self] in
            self?.processNALUnits(data)
        }
    }
}

// MARK: - Private
extension H264Decoder {
    private func processNALUnits(_ data: Data) {
        let startCode: [UInt8] = [0x00, 0x00, 0x00, 0x01]
        var offset = 0
        var nalUnits: [(type: UInt8, data: Data)] = []

        // NAL unit 파싱
        while offset < data.count - 4 {
            // start code 찾기
            guard data[offset..<offset+4].elementsEqual(startCode) else {
                offset += 1
                continue
            }

            let nalStart = offset + 4
            var nalEnd = data.count

            // 다음 start code 찾기
            for i in nalStart..<(data.count - 3) {
                if data[i..<i+4].elementsEqual(startCode) {
                    nalEnd = i
                    break
                }
            }

            let nalData = data[nalStart..<nalEnd]
            if let firstByte = nalData.first {
                let nalType = firstByte & 0x1F
                nalUnits.append((type: nalType, data: Data(nalData)))
            }

            offset = nalEnd
        }

        // NAL unit 처리
        for nal in nalUnits {
            switch nal.type {
            case 7: // SPS
                if sps != nal.data {
                    sps = nal.data
                    // SPS와 PPS가 모두 있으면 FormatDescription 생성
                    if pps != nil {
                        ensureDecompressionSession()
                    }
                }
            case 8: // PPS
                if pps != nal.data {
                    pps = nal.data
                    // SPS와 PPS가 모두 있으면 FormatDescription 생성
                    if sps != nil {
                        ensureDecompressionSession()
                    }
                }
            case 5: // IDR (키프레임)
                ensureDecompressionSession()
                if decompressionSession != nil {
                    decodeFrame(nal.data, isKeyframe: true)
                } else {
                    logger.warning("DecompressionSession이 없어 IDR 프레임을 디코딩할 수 없습니다")
                }
            case 1: // Non-IDR (일반 프레임)
                guard decompressionSession != nil else {
                    continue
                }
                decodeFrame(nal.data, isKeyframe: false)
            default:
                break
            }
        }
    }

    /// FormatDescription과 DecompressionSession이 준비되었는지 확인
    private func ensureDecompressionSession() {
        if formatDescription == nil {
            createFormatDescription()
        }
        if decompressionSession == nil && formatDescription != nil {
            createDecompressionSession()
        }
    }

    private func createFormatDescription() {
        guard let sps = sps, let pps = pps else { return }

        var formatDesc: CMFormatDescription?

        // withUnsafeBytes 클로저 내부에서 포인터 사용
        let status = sps.withUnsafeBytes { spsPtr -> OSStatus in
            pps.withUnsafeBytes { ppsPtr -> OSStatus in
                let parameterSets: [UnsafePointer<UInt8>] = [
                    spsPtr.baseAddress!.assumingMemoryBound(to: UInt8.self),
                    ppsPtr.baseAddress!.assumingMemoryBound(to: UInt8.self)
                ]
                let parameterSetSizes: [Int] = [sps.count, pps.count]

                return CMVideoFormatDescriptionCreateFromH264ParameterSets(
                    allocator: kCFAllocatorDefault,
                    parameterSetCount: 2,
                    parameterSetPointers: parameterSets,
                    parameterSetSizes: parameterSetSizes,
                    nalUnitHeaderLength: 4,
                    formatDescriptionOut: &formatDesc
                )
            }
        }

        if status == noErr {
            formatDescription = formatDesc
        } else {
            logger.warning("FormatDescription 생성 실패: \(status)")
        }
    }

    private func createDecompressionSession() {
        guard let formatDescription = formatDescription else { return }

        let decoderParameters: [CFString: Any] = [
            kVTDecompressionPropertyKey_RealTime: kCFBooleanTrue!
        ]

        var outputCallback = VTDecompressionOutputCallbackRecord(
            decompressionOutputCallback: decompressionOutputCallback,
            decompressionOutputRefCon: Unmanaged.passUnretained(self).toOpaque()
        )

        var session: VTDecompressionSession?
        let status = VTDecompressionSessionCreate(
            allocator: kCFAllocatorDefault,
            formatDescription: formatDescription,
            decoderSpecification: nil,
            imageBufferAttributes: nil,
            outputCallback: &outputCallback,
            decompressionSessionOut: &session
        )

        if status == noErr {
            decompressionSession = session
        } else {
            logger.warning("DecompressionSession 생성 실패: \(status)")
        }
    }

    private func decodeFrame(_ nalData: Data, isKeyframe: Bool) {
        guard let session = decompressionSession,
              let formatDescription = formatDescription else { return }

        // AVCC 형식으로 변환 (4바이트 길이 헤더)
        var length = UInt32(nalData.count).bigEndian
        var avccData = Data(bytes: &length, count: 4)
        avccData.append(nalData)

        // CMBlockBuffer 생성 (메모리 복사 방식)
        var blockBuffer: CMBlockBuffer?
        var blockStatus: OSStatus = noErr

        avccData.withUnsafeBytes { bytes in
            blockStatus = CMBlockBufferCreateWithMemoryBlock(
                allocator: kCFAllocatorDefault,
                memoryBlock: nil,
                blockLength: avccData.count,
                blockAllocator: kCFAllocatorDefault,
                customBlockSource: nil,
                offsetToData: 0,
                dataLength: avccData.count,
                flags: 0,
                blockBufferOut: &blockBuffer
            )

            if blockStatus == noErr, let buffer = blockBuffer {
                blockStatus = CMBlockBufferReplaceDataBytes(
                    with: bytes.baseAddress!,
                    blockBuffer: buffer,
                    offsetIntoDestination: 0,
                    dataLength: avccData.count
                )
            }
        }

        guard blockStatus == noErr, let buffer = blockBuffer else {
            if isKeyframe {
                logger.warning("BlockBuffer 생성 실패 (키프레임): \(blockStatus)")
            }
            return
        }

        // CMSampleBuffer 생성
        var sampleBuffer: CMSampleBuffer?
        var sampleSize = avccData.count

        let pts = CMTime(
            value: CMTimeValue(CACurrentMediaTime() * 1_000_000),
            timescale: 1_000_000
        )

        var timing = CMSampleTimingInfo(
            duration: CMTime(value: 1, timescale: 30),
            presentationTimeStamp: pts,
            decodeTimeStamp: .invalid
        )

        let sampleStatus = CMSampleBufferCreateReady(
            allocator: kCFAllocatorDefault,
            dataBuffer: buffer,
            formatDescription: formatDescription,
            sampleCount: 1,
            sampleTimingEntryCount: 1,
            sampleTimingArray: &timing,
            sampleSizeEntryCount: 1,
            sampleSizeArray: &sampleSize,
            sampleBufferOut: &sampleBuffer
        )

        guard sampleStatus == noErr, let sample = sampleBuffer else {
            if isKeyframe {
                logger.warning("SampleBuffer 생성 실패 (키프레임): \(sampleStatus)")
            }
            return
        }

        // 디코딩
        let decodeStatus = VTDecompressionSessionDecodeFrame(
            session,
            sampleBuffer: sample,
            flags: [._EnableAsynchronousDecompression],
            frameRefcon: nil,
            infoFlagsOut: nil
        )

        if decodeStatus != noErr {
            if isKeyframe {
                logger.warning("디코딩 실패 (키프레임): \(decodeStatus)")
            }
        }
    }

    func handleDecodedFrame(_ imageBuffer: CVImageBuffer, presentationTimeStamp: CMTime) {
        // CVImageBuffer -> CMSampleBuffer 변환
        var formatDesc: CMVideoFormatDescription?
        let formatStatus = CMVideoFormatDescriptionCreateForImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: imageBuffer,
            formatDescriptionOut: &formatDesc
        )

        guard formatStatus == noErr, let format = formatDesc else {
            logger.warning("FormatDescription 생성 실패 (디코딩 출력): \(formatStatus)")
            return
        }

        var timing = CMSampleTimingInfo(
            duration: .invalid,
            presentationTimeStamp: presentationTimeStamp,
            decodeTimeStamp: .invalid
        )

        var sampleBuffer: CMSampleBuffer?
        let sampleStatus = CMSampleBufferCreateForImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: imageBuffer,
            dataReady: true,
            makeDataReadyCallback: nil,
            refcon: nil,
            formatDescription: format,
            sampleTiming: &timing,
            sampleBufferOut: &sampleBuffer
        )

        if sampleStatus == noErr, let sample = sampleBuffer {
            onDecodedSampleBuffer?(sample)
        } else {
            logger.warning("SampleBuffer 생성 실패 (디코딩 출력): \(sampleStatus)")
        }
    }
}

// MARK: - Decompression Output Callback
private func decompressionOutputCallback(
    decompressionOutputRefCon: UnsafeMutableRawPointer?,
    sourceFrameRefCon: UnsafeMutableRawPointer?,
    status: OSStatus,
    infoFlags: VTDecodeInfoFlags,
    imageBuffer: CVImageBuffer?,
    presentationTimeStamp: CMTime,
    presentationDuration: CMTime
) {
    guard let refcon = decompressionOutputRefCon else { return }

    let decoder = Unmanaged<H264Decoder>.fromOpaque(refcon).takeUnretainedValue()

    guard status == noErr else {
        decoder.logger.warning("디코딩 콜백 실패: \(status)")
        return
    }

    guard let buffer = imageBuffer else {
        decoder.logger.warning("디코딩 콜백: imageBuffer가 nil")
        return
    }

    decoder.handleDecodedFrame(buffer, presentationTimeStamp: presentationTimeStamp)
}
