//
//  HEVCDecoder.swift
//  mirroringBooth
//
//  Created by 최윤진 on 12/23/25.
//

import VideoToolbox
import CoreImage
import CoreMedia

final class HEVCDecoder {
    typealias DecodedImageHandler = (CIImage) -> Void

    private var decompressionSession: VTDecompressionSession?
    private var formatDescription: CMVideoFormatDescription?
    private var decodedImageHandler: DecodedImageHandler?

    private var vpsData: Data?
    private var spsData: Data?
    private var ppsData: Data?

    func setDecodedImageHandler(_ handler: @escaping DecodedImageHandler) {
        self.decodedImageHandler = handler
    }

    func decode(_ frameData: Data) {
        let nalUnits = parseNALUnits(from: frameData)

        for nalUnit in nalUnits {
            processNALUnit(nalUnit)
        }
    }

    func invalidate() {
        if let session = decompressionSession {
            VTDecompressionSessionInvalidate(session)
            decompressionSession = nil
        }
        formatDescription = nil
    }

    // MARK: - Private

    private func parseNALUnits(from data: Data) -> [Data] {
        var nalUnits: [Data] = []
        var currentIndex = 0
        let startCode3: [UInt8] = [0x00, 0x00, 0x01]
        let startCode4: [UInt8] = [0x00, 0x00, 0x00, 0x01]

        while currentIndex < data.count {
            var startCodeLength = 0
            var nextStartIndex = data.count

            for searchIndex in (currentIndex + 3)..<data.count {
                if searchIndex + 3 <= data.count {
                    let slice3 = data.subdata(in: searchIndex..<(searchIndex + 3))
                    if slice3.elementsEqual(startCode3) {
                        nextStartIndex = searchIndex
                        break
                    }
                }
                if searchIndex + 4 <= data.count {
                    let slice4 = data.subdata(in: searchIndex..<(searchIndex + 4))
                    if slice4.elementsEqual(startCode4) {
                        nextStartIndex = searchIndex
                        break
                    }
                }
            }

            if currentIndex + 4 <= data.count {
                let slice4 = data.subdata(in: currentIndex..<(currentIndex + 4))
                if slice4.elementsEqual(startCode4) {
                    startCodeLength = 4
                } else if data.subdata(in: currentIndex..<(currentIndex + 3)).elementsEqual(startCode3) {
                    startCodeLength = 3
                }
            } else if currentIndex + 3 <= data.count {
                let slice3 = data.subdata(in: currentIndex..<(currentIndex + 3))
                if slice3.elementsEqual(startCode3) {
                    startCodeLength = 3
                }
            }

            if startCodeLength > 0 {
                let nalStart = currentIndex + startCodeLength
                if nalStart < nextStartIndex {
                    let nalData = data.subdata(in: nalStart..<nextStartIndex)
                    nalUnits.append(nalData)
                }
            }

            currentIndex = nextStartIndex
        }

        return nalUnits
    }

    private func processNALUnit(_ nalUnit: Data) {
        guard !nalUnit.isEmpty else { return }

        let nalUnitType = (nalUnit[0] >> 1) & 0x3F

        switch nalUnitType {
        case 32: // VPS
            vpsData = nalUnit
        case 33: // SPS
            spsData = nalUnit
        case 34: // PPS
            ppsData = nalUnit
            createFormatDescriptionIfNeeded()
        case 19, 20, 21: // IDR frames
            decodeVideoFrame(nalUnit)
        case 0, 1: // Non-IDR frames
            decodeVideoFrame(nalUnit)
        default:
            break
        }
    }

    private func createFormatDescriptionIfNeeded() {
        guard let vps = vpsData,
              let sps = spsData,
              let pps = ppsData else { return }

        var newFormatDescription: CMVideoFormatDescription?

        let status = vps.withUnsafeBytes { vpsBuffer in
            sps.withUnsafeBytes { spsBuffer in
                pps.withUnsafeBytes { ppsBuffer in
                    let parameterSetPointers: [UnsafePointer<UInt8>] = [
                        vpsBuffer.baseAddress!.assumingMemoryBound(to: UInt8.self),
                        spsBuffer.baseAddress!.assumingMemoryBound(to: UInt8.self),
                        ppsBuffer.baseAddress!.assumingMemoryBound(to: UInt8.self)
                    ]
                    let parameterSetSizes: [Int] = [vps.count, sps.count, pps.count]

                    return parameterSetPointers.withUnsafeBufferPointer { pointersBuffer in
                        parameterSetSizes.withUnsafeBufferPointer { sizesBuffer in
                            CMVideoFormatDescriptionCreateFromHEVCParameterSets(
                                allocator: kCFAllocatorDefault,
                                parameterSetCount: 3,
                                parameterSetPointers: pointersBuffer.baseAddress!,
                                parameterSetSizes: sizesBuffer.baseAddress!,
                                nalUnitHeaderLength: 4,
                                extensions: nil,
                                formatDescriptionOut: &newFormatDescription
                            )
                        }
                    }
                }
            }
        }

        if status == noErr, let description = newFormatDescription {
            formatDescription = description
            createDecompressionSession()
        }
    }

    private func createDecompressionSession() {
        guard let formatDescription = formatDescription else { return }

        if let existingSession = decompressionSession {
            VTDecompressionSessionInvalidate(existingSession)
            decompressionSession = nil
        }

        let destinationAttributes: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]

        var callbackRecord = VTDecompressionOutputCallbackRecord()
        callbackRecord.decompressionOutputCallback = { decompressionOutputRefCon, _, status, _, imageBuffer, _, _ in
            guard status == noErr,
                  let imageBuffer = imageBuffer,
                  let refCon = decompressionOutputRefCon else { return }

            let decoder = Unmanaged<HEVCDecoder>.fromOpaque(refCon).takeUnretainedValue()
            let ciImage = CIImage(cvPixelBuffer: imageBuffer)

            DispatchQueue.main.async {
                decoder.decodedImageHandler?(ciImage)
            }
        }
        callbackRecord.decompressionOutputRefCon = Unmanaged.passUnretained(self).toOpaque()

        VTDecompressionSessionCreate(
            allocator: kCFAllocatorDefault,
            formatDescription: formatDescription,
            decoderSpecification: nil,
            imageBufferAttributes: destinationAttributes as CFDictionary,
            outputCallback: &callbackRecord,
            decompressionSessionOut: &decompressionSession
        )
    }

    private func decodeVideoFrame(_ nalUnit: Data) {
        guard let session = decompressionSession,
              let formatDescription = formatDescription else { return }

        var lengthBytes = UInt32(nalUnit.count).bigEndian
        var frameData = Data(bytes: &lengthBytes, count: 4)
        frameData.append(nalUnit)

        var blockBuffer: CMBlockBuffer?
        let dataCount = frameData.count

        frameData.withUnsafeBytes { rawBufferPointer in
            guard let baseAddress = rawBufferPointer.baseAddress else { return }
            let mutablePointer = UnsafeMutablePointer<Int8>.allocate(capacity: dataCount)
            mutablePointer.initialize(from: baseAddress.assumingMemoryBound(to: Int8.self), count: dataCount)

            CMBlockBufferCreateWithMemoryBlock(
                allocator: kCFAllocatorDefault,
                memoryBlock: mutablePointer,
                blockLength: dataCount,
                blockAllocator: kCFAllocatorDefault,
                customBlockSource: nil,
                offsetToData: 0,
                dataLength: dataCount,
                flags: 0,
                blockBufferOut: &blockBuffer
            )
        }

        guard let buffer = blockBuffer else { return }

        var sampleBuffer: CMSampleBuffer?
        var sampleSizeArray = [dataCount]

        CMSampleBufferCreateReady(
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

        guard let sample = sampleBuffer else { return }

        VTDecompressionSessionDecodeFrame(
            session,
            sampleBuffer: sample,
            flags: [._EnableAsynchronousDecompression],
            frameRefcon: nil,
            infoFlagsOut: nil
        )
    }
}
