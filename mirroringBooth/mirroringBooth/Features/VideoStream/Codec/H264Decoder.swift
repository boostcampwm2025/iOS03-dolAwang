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
        logger.info("H.264 디코더 시작")
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
        logger.info("H.264 디코더 중지")
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
                sps = nal.data
            case 8: // PPS
                pps = nal.data
            case 5: // IDR (키프레임)
                if formatDescription == nil {
                    createFormatDescription()
                }
                if decompressionSession == nil {
                    createDecompressionSession()
                }
                decodeFrame(nal.data)
            case 1: // Non-IDR (일반 프레임)
                decodeFrame(nal.data)
            default:
                break
            }
        }
    }

    private func createFormatDescription() {
        guard let sps = sps, let pps = pps else { return }

        let parameterSets: [UnsafePointer<UInt8>] = [
            sps.withUnsafeBytes { $0.baseAddress!.assumingMemoryBound(to: UInt8.self) },
            pps.withUnsafeBytes { $0.baseAddress!.assumingMemoryBound(to: UInt8.self) }
        ]
        let parameterSetSizes: [Int] = [sps.count, pps.count]

        var formatDesc: CMFormatDescription?
        let status = CMVideoFormatDescriptionCreateFromH264ParameterSets(
            allocator: kCFAllocatorDefault,
            parameterSetCount: 2,
            parameterSetPointers: parameterSets,
            parameterSetSizes: parameterSetSizes,
            nalUnitHeaderLength: 4,
            formatDescriptionOut: &formatDesc
        )

        if status == noErr {
            formatDescription = formatDesc
            logger.info("FormatDescription 생성 완료")
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
            logger.info("DecompressionSession 생성 완료")
        } else {
            logger.warning("DecompressionSession 생성 실패: \(status)")
        }
    }

    private func decodeFrame(_ nalData: Data) {
        guard let session = decompressionSession,
              let formatDescription = formatDescription else { return }

        // AVCC 형식으로 변환 (4바이트 길이 헤더)
        var avccData = Data()
        var length = UInt32(nalData.count).bigEndian
        avccData.append(Data(bytes: &length, count: 4))
        avccData.append(nalData)

        // CMBlockBuffer 생성
        var blockBuffer: CMBlockBuffer?
        let blockStatus = avccData.withUnsafeBytes { ptr -> OSStatus in
            CMBlockBufferCreateWithMemoryBlock(
                allocator: kCFAllocatorDefault,
                memoryBlock: UnsafeMutableRawPointer(mutating: ptr.baseAddress),
                blockLength: avccData.count,
                blockAllocator: kCFAllocatorNull,
                customBlockSource: nil,
                offsetToData: 0,
                dataLength: avccData.count,
                flags: 0,
                blockBufferOut: &blockBuffer
            )
        }

        guard blockStatus == noErr, let buffer = blockBuffer else { return }

        // CMSampleBuffer 생성
        var sampleBuffer: CMSampleBuffer?
        var sampleSize = avccData.count
        CMSampleBufferCreateReady(
            allocator: kCFAllocatorDefault,
            dataBuffer: buffer,
            formatDescription: formatDescription,
            sampleCount: 1,
            sampleTimingEntryCount: 0,
            sampleTimingArray: nil,
            sampleSizeEntryCount: 1,
            sampleSizeArray: &sampleSize,
            sampleBufferOut: &sampleBuffer
        )

        guard let sample = sampleBuffer else { return }

        // 디코딩
        VTDecompressionSessionDecodeFrame(
            session,
            sampleBuffer: sample,
            flags: [._EnableAsynchronousDecompression],
            frameRefcon: nil,
            infoFlagsOut: nil
        )
    }

    func handleDecodedFrame(_ imageBuffer: CVImageBuffer, presentationTimeStamp: CMTime) {
        // CVImageBuffer -> CMSampleBuffer 변환
        var formatDesc: CMVideoFormatDescription?
        CMVideoFormatDescriptionCreateForImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: imageBuffer,
            formatDescriptionOut: &formatDesc
        )

        guard let format = formatDesc else { return }

        var timing = CMSampleTimingInfo(
            duration: .invalid,
            presentationTimeStamp: presentationTimeStamp,
            decodeTimeStamp: .invalid
        )

        var sampleBuffer: CMSampleBuffer?
        CMSampleBufferCreateForImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: imageBuffer,
            dataReady: true,
            makeDataReadyCallback: nil,
            refcon: nil,
            formatDescription: format,
            sampleTiming: &timing,
            sampleBufferOut: &sampleBuffer
        )

        if let sample = sampleBuffer {
            onDecodedSampleBuffer?(sample)
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
    guard let refcon = decompressionOutputRefCon,
          status == noErr,
          let buffer = imageBuffer else { return }

    let decoder = Unmanaged<H264Decoder>.fromOpaque(refcon).takeUnretainedValue()
    decoder.handleDecodedFrame(buffer, presentationTimeStamp: presentationTimeStamp)
}
