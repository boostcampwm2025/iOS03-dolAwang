//
//  HEVCEncoder.swift
//  mirroringBooth
//
//  Created by 최윤진 on 12/23/25.
//

import VideoToolbox
import CoreImage
import CoreMedia

final class HEVCEncoder {
    typealias EncodedFrameHandler = (Data) -> Void

    private var compressionSession: VTCompressionSession?
    private var encodedFrameHandler: EncodedFrameHandler?

    private let width: Int32
    private let height: Int32
    private let bitrate: Int
    private let expectedFrameRate: Int

    private let ciContext = CIContext()

    init(
        width: Int32,
        height: Int32,
        bitrate: Int = 2_000_000,
        expectedFrameRate: Int = 30
    ) {
        self.width = width
        self.height = height
        self.bitrate = bitrate
        self.expectedFrameRate = expectedFrameRate
    }

    deinit {
        invalidate()
    }

    func setEncodedFrameHandler(_ handler: @escaping EncodedFrameHandler) {
        self.encodedFrameHandler = handler
    }

    func prepareEncoder() -> Bool {
        let encoderCallback: VTCompressionOutputCallback = { outputCallbackRefCon, _, status, _, sampleBuffer in
            guard status == noErr,
                  let sampleBuffer = sampleBuffer,
                  let refCon = outputCallbackRefCon else { return }

            let encoder = Unmanaged<HEVCEncoder>.fromOpaque(refCon).takeUnretainedValue()
            encoder.handleEncodedSampleBuffer(sampleBuffer)
        }

        let status = VTCompressionSessionCreate(
            allocator: kCFAllocatorDefault,
            width: width,
            height: height,
            codecType: kCMVideoCodecType_HEVC,
            encoderSpecification: nil,
            imageBufferAttributes: nil,
            compressedDataAllocator: nil,
            outputCallback: encoderCallback,
            refcon: Unmanaged.passUnretained(self).toOpaque(),
            compressionSessionOut: &compressionSession
        )

        guard status == noErr, let session = compressionSession else {
            return false
        }

        configureSessionProperties(session)

        let prepareStatus = VTCompressionSessionPrepareToEncodeFrames(session)
        return prepareStatus == noErr
    }

    func encode(_ ciImage: CIImage, presentationTimeStamp: CMTime) {
        guard let session = compressionSession else { return }

        guard let pixelBuffer = createPixelBuffer(from: ciImage) else { return }

        VTCompressionSessionEncodeFrame(
            session,
            imageBuffer: pixelBuffer,
            presentationTimeStamp: presentationTimeStamp,
            duration: .invalid,
            frameProperties: nil,
            sourceFrameRefcon: nil,
            infoFlagsOut: nil
        )
    }

    func invalidate() {
        guard let session = compressionSession else { return }
        VTCompressionSessionCompleteFrames(session, untilPresentationTimeStamp: .invalid)
        VTCompressionSessionInvalidate(session)
        compressionSession = nil
    }

    // MARK: - Private

    private func configureSessionProperties(_ session: VTCompressionSession) {
        VTSessionSetProperty(session, key: kVTCompressionPropertyKey_RealTime, value: kCFBooleanTrue)
        VTSessionSetProperty(session, key: kVTCompressionPropertyKey_ProfileLevel, value: kVTProfileLevel_HEVC_Main_AutoLevel)
        VTSessionSetProperty(session, key: kVTCompressionPropertyKey_AverageBitRate, value: bitrate as CFNumber)
        VTSessionSetProperty(session, key: kVTCompressionPropertyKey_ExpectedFrameRate, value: expectedFrameRate as CFNumber)
        VTSessionSetProperty(session, key: kVTCompressionPropertyKey_MaxKeyFrameInterval, value: expectedFrameRate as CFNumber)
        VTSessionSetProperty(session, key: kVTCompressionPropertyKey_AllowFrameReordering, value: kCFBooleanFalse)
    }

    private func createPixelBuffer(from ciImage: CIImage) -> CVPixelBuffer? {
        var pixelBuffer: CVPixelBuffer?
        let attributes: [String: Any] = [
            kCVPixelBufferCGImageCompatibilityKey as String: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: true
        ]

        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            Int(width),
            Int(height),
            kCVPixelFormatType_32BGRA,
            attributes as CFDictionary,
            &pixelBuffer
        )

        guard status == kCVReturnSuccess, let buffer = pixelBuffer else { return nil }

        ciContext.render(ciImage, to: buffer)
        return buffer
    }

    private func handleEncodedSampleBuffer(_ sampleBuffer: CMSampleBuffer) {
        guard let dataBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) else { return }

        var totalLength: Int = 0
        var dataPointer: UnsafeMutablePointer<Int8>?

        let status = CMBlockBufferGetDataPointer(
            dataBuffer,
            atOffset: 0,
            lengthAtOffsetOut: nil,
            totalLengthOut: &totalLength,
            dataPointerOut: &dataPointer
        )

        guard status == kCMBlockBufferNoErr, let pointer = dataPointer else { return }

        var frameData = Data()

        if let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer) {
            let attachments = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, createIfNecessary: false)
            var isKeyFrame = true

            if let attachmentsArray = attachments as? [[CFString: Any]],
               let firstAttachment = attachmentsArray.first {
                isKeyFrame = !(firstAttachment[kCMSampleAttachmentKey_NotSync] as? Bool ?? false)
            }

            if isKeyFrame {
                if let parameterSetData = extractParameterSets(from: formatDescription) {
                    frameData.append(parameterSetData)
                }
            }
        }

        // AVCC → Annex-B 변환
        let rawData = Data(bytes: pointer, count: totalLength)
        let convertedData = convertAVCCToAnnexB(rawData)
        frameData.append(convertedData)

        encodedFrameHandler?(frameData)
    }

    private func convertAVCCToAnnexB(_ avccData: Data) -> Data {
        var annexBData = Data()
        var index = 0

        while index + 4 <= avccData.count {
            let lengthBytes = avccData.subdata(in: index..<(index + 4))
            let nalLength = lengthBytes.withUnsafeBytes { $0.load(as: UInt32.self).bigEndian }

            index += 4

            guard index + Int(nalLength) <= avccData.count else { break }

            annexBData.append(contentsOf: [0x00, 0x00, 0x00, 0x01])
            annexBData.append(avccData.subdata(in: index..<(index + Int(nalLength))))

            index += Int(nalLength)
        }

        return annexBData
    }

    private func extractParameterSets(from formatDescription: CMFormatDescription) -> Data? {
        var parameterSetData = Data()

        var vpsSize: Int = 0
        var vpsCount: Int = 0
        var vpsPointer: UnsafePointer<UInt8>?

        if CMVideoFormatDescriptionGetHEVCParameterSetAtIndex(
            formatDescription,
            parameterSetIndex: 0,
            parameterSetPointerOut: &vpsPointer,
            parameterSetSizeOut: &vpsSize,
            parameterSetCountOut: &vpsCount,
            nalUnitHeaderLengthOut: nil
        ) == noErr, let vps = vpsPointer {
            parameterSetData.append(contentsOf: [0x00, 0x00, 0x00, 0x01])
            parameterSetData.append(Data(bytes: vps, count: vpsSize))
        }

        var spsSize: Int = 0
        var spsPointer: UnsafePointer<UInt8>?

        if CMVideoFormatDescriptionGetHEVCParameterSetAtIndex(
            formatDescription,
            parameterSetIndex: 1,
            parameterSetPointerOut: &spsPointer,
            parameterSetSizeOut: &spsSize,
            parameterSetCountOut: nil,
            nalUnitHeaderLengthOut: nil
        ) == noErr, let sps = spsPointer {
            parameterSetData.append(contentsOf: [0x00, 0x00, 0x00, 0x01])
            parameterSetData.append(Data(bytes: sps, count: spsSize))
        }

        var ppsSize: Int = 0
        var ppsPointer: UnsafePointer<UInt8>?

        if CMVideoFormatDescriptionGetHEVCParameterSetAtIndex(
            formatDescription,
            parameterSetIndex: 2,
            parameterSetPointerOut: &ppsPointer,
            parameterSetSizeOut: &ppsSize,
            parameterSetCountOut: nil,
            nalUnitHeaderLengthOut: nil
        ) == noErr, let pps = ppsPointer {
            parameterSetData.append(contentsOf: [0x00, 0x00, 0x00, 0x01])
            parameterSetData.append(Data(bytes: pps, count: ppsSize))
        }

        return parameterSetData.isEmpty ? nil : parameterSetData
    }
}
