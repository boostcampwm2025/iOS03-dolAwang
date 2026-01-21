//
//  H264Decoder.swift
//  mirroringBooth
//
//  Created by 윤대현 on 1/2/26.
//

import CoreMedia
import Foundation
import ImageIO
import OSLog
import QuartzCore
import VideoToolbox

@Observable
final class H264Decoder {
    let logger = Logger.h264decoder
    private let decoderQueue = DispatchQueue(label: "decoder.queue")
    private var formatDescription: CMVideoFormatDescription?

    /// 디코딩된 샘플 버퍼를 받는 콜백
    var onDecodedSampleBuffer: ((CMSampleBuffer, Int16) -> Void)?

    // SPS/PPS 저장
    private var sps: Data?
    private var pps: Data?

    // Browser에서 보낸 회전 각도
    private var rotationAngle = Int16.zero

    func stop() {
        decoderQueue.async { [weak self] in
            self?.formatDescription = nil
            self?.sps = nil
            self?.pps = nil
        }
    }

    func decode(_ data: Data) {
        decoderQueue.async { [weak self] in
            if 6 <= data.count {
                let startIndex = data.startIndex
                let isAnnexBAtStart =
                    data[startIndex] == 0x00 &&
                    data[startIndex + 1] == 0x00 &&
                    data[startIndex + 2] == 0x00 &&
                    data[startIndex + 3] == 0x01

                if !isAnnexBAtStart {
                    let angleBytesRange = data.startIndex..<(data.startIndex + 2)
                    let angleBytes = data.subdata(in: angleBytesRange)

                    let angleValue = angleBytes.withUnsafeBytes { rawBufferPointer -> Int16? in
                        guard MemoryLayout<Int16>.size <= rawBufferPointer.count else { return nil }
                        return rawBufferPointer.loadUnaligned(as: Int16.self).littleEndian
                    }

                    if let angleValue = angleValue {
                        self?.rotationAngle = angleValue

                        let trimmedDataRange = (data.startIndex + 2)..<data.endIndex
                        let trimmedData = data.subdata(in: trimmedDataRange)
                        self?.processNALUnits(trimmedData)
                        return
                    }
                }
            }

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
            for index in nalStart..<(data.count - 3) where data[index..<index+4].elementsEqual(startCode) {
                nalEnd = index
                break
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
            handleNalUnit(type: nal.type, data: nal.data)
        }
    }

    private func handleNalUnit(type: UInt8, data: Data) {
        switch type {
        case 7: // SPS
            if sps != data {
                sps = data
                if pps != nil {
                    ensureDecompressionSession()
                }
            }
        case 8: // PPS
            if pps != data {
                pps = data
                if sps != nil {
                    ensureDecompressionSession()
                }
            }
        case 5: // IDR (키프레임)
            ensureDecompressionSession()
            decodeFrame(data, isKeyframe: true)
        case 1: // Non-IDR (일반 프레임)
            decodeFrame(data, isKeyframe: false)
        default:
            break
        }
    }

    /// FormatDescription과 DecompressionSession이 준비되었는지 확인
    private func ensureDecompressionSession() {
        if formatDescription == nil {
            createFormatDescription()
        }
    }

    private func createFormatDescription() {
        guard let sps = sps, let pps = pps else { return }

        var formatDesc: CMFormatDescription?

        // withUnsafeBytes 클로저 내부에서 포인터 사용
        let status = sps.withUnsafeBytes { spsPtr -> OSStatus in
            guard let spsBaseAddress = spsPtr.baseAddress else {
                return -1
            }
            return pps.withUnsafeBytes { ppsPtr -> OSStatus in
                guard let ppsBaseAddress = ppsPtr.baseAddress else {
                    return -1
                }
                let parameterSets: [UnsafePointer<UInt8>] = [
                    spsBaseAddress.assumingMemoryBound(to: UInt8.self),
                    ppsBaseAddress.assumingMemoryBound(to: UInt8.self)
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

    private func decodeFrame(_ nalData: Data, isKeyframe: Bool) {
        guard let formatDescription = formatDescription else {
            logger.warning("formatDescription이 없음")
            return
        }

        // AVCC 형식으로 변환 (4바이트 길이 헤더)
        var length = UInt32(nalData.count).bigEndian
        var avccData = Data(bytes: &length, count: 4)
        avccData.append(nalData)

        // CMBlockBuffer 생성 (메모리 복사 방식)
        guard let buffer = makeBlockBuffer(avccData, isKeyframe: isKeyframe) else { return }

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

        guard sampleStatus == noErr, sampleBuffer != nil else {
            if isKeyframe {
                logger.warning("SampleBuffer 생성 실패 (키프레임): \(sampleStatus)")
            }
            return
        }

        if sampleStatus == noErr, let sample = sampleBuffer {
            onDecodedSampleBuffer?(sample, self.rotationAngle)
        } else {
            logger.warning("SampleBuffer 생성 실패 (디코딩 출력): \(sampleStatus)")
        }
    }

    private func makeBlockBuffer(_ avccData: Data, isKeyframe: Bool) -> CMBlockBuffer? {
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

            if blockStatus == noErr,
               let buffer: CMBlockBuffer = blockBuffer,
               let baseAddress: UnsafeRawPointer = bytes.baseAddress {
                blockStatus = CMBlockBufferReplaceDataBytes(
                    with: baseAddress,
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
            return nil
        }

        return buffer
    }
}
