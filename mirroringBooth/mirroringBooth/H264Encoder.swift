//
//  H264Encoder.swift
//  mirroringBooth
//
//  Created by Liam on 1/1/26.
//

import Foundation
import VideoToolbox

protocol H264EncoderDelegate: AnyObject {
    func videoEncoder(_ encoder: H264Encoder, didEncode data: Data)
}

final class H264Encoder: NSObject {
    weak var delegate: H264EncoderDelegate?
    private var session: VTCompressionSession?
    private var width: Int32 = 0
    private var height: Int32 = 0
    
    func configure(width: Int32, height: Int32) {
        self.width = width
        self.height = height
        
        let status = VTCompressionSessionCreate(
            allocator: kCFAllocatorDefault,
            width: width,
            height: height,
            codecType: kCMVideoCodecType_H264,
            encoderSpecification: nil,
            imageBufferAttributes: nil,
            compressedDataAllocator: nil,
            outputCallback: compressionCallback,
            refcon: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()), // self 전달
            compressionSessionOut: &session
        )
        
        guard status == noErr, let session = session else {
            print("❌ 인코더 세션 생성 실패: \(status)")
            return
        }
        
        // 2. 속성 설정 (실시간 스트리밍용)
        VTSessionSetProperty(session, key: kVTCompressionPropertyKey_RealTime, value: kCFBooleanTrue)
        VTSessionSetProperty(session, key: kVTCompressionPropertyKey_ProfileLevel, value: kVTProfileLevel_H264_Main_AutoLevel)
        
        // 3. 키프레임 간격 (중요: 1초에 한 번은 온전한 사진을 보냄)
        // 이게 너무 길면, 중간에 들어온 사람은 화면이 깨짐
        let frameRate: Int32 = 30
        VTSessionSetProperty(session, key: kVTCompressionPropertyKey_MaxKeyFrameInterval, value: frameRate as CFNumber)
        
        // 4. 비트레이트 (화질 vs 용량 조절) - 1Mbps 정도로 설정
        let bitRate = 1_000_000
        VTSessionSetProperty(session, key: kVTCompressionPropertyKey_AverageBitRate, value: bitRate as CFNumber)
        
        print("✅ H.264 인코더 설정 완료 (\(width)x\(height))")
    }
    
    // 외부에서 부르는 함수: "이거 압축해줘"
    func encode(sampleBuffer: CMSampleBuffer) {
        guard let session = session,
              let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        let duration = CMSampleBufferGetDuration(sampleBuffer)
        
        // 프레임 인코딩 요청
        VTCompressionSessionEncodeFrame(
            session,
            imageBuffer: imageBuffer,
            presentationTimeStamp: timestamp,
            duration: duration,
            frameProperties: nil,
            sourceFrameRefcon: nil,
            infoFlagsOut: nil
        )
    }
}

private func compressionCallback(
    outputCallbackRefCon: UnsafeMutableRawPointer?,
    sourceFrameRefCon: UnsafeMutableRawPointer?,
    status: OSStatus,
    infoFlags: VTEncodeInfoFlags,
    sampleBuffer: CMSampleBuffer?
) {
    guard status == noErr, let sampleBuffer = sampleBuffer,
          let context = outputCallbackRefCon else { return }
    
    // 1. UnsafePointer를 다시 Swift 클래스(self)로 변환
    let encoder = Unmanaged<H264Encoder>.fromOpaque(context).takeUnretainedValue()
    
    // 2. 키프레임인지 확인 (I-Frame)
    var isKeyFrame = false
    if let attachments = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, createIfNecessary: true) as? [[CFString: Any]],
       let firstAttachment = attachments.first {
        let notSync = firstAttachment[kCMSampleAttachmentKey_NotSync] as? Bool ?? false
        isKeyFrame = !notSync
    } else {
        isKeyFrame = true
    }
    
    // 3. 데이터를 추출해서 Delegate로 전달
    if let data = encoder.convertSampleBufferToH264Data(sampleBuffer, isKeyFrame: isKeyFrame) {
        encoder.delegate?.videoEncoder(encoder, didEncode: data)
    }
}

extension H264Encoder {
    func convertSampleBufferToH264Data(_ sampleBuffer: CMSampleBuffer, isKeyFrame: Bool) -> Data? {
        var videoData = Data()
        if isKeyFrame {
            guard let format = CMSampleBufferGetFormatDescription(sampleBuffer) else { return nil }

            var spsSize: Int = 0
            var spsCount: Int = 0
            var ppsSize: Int = 0
            var ppsCount: Int = 0
            var spsHeader: UnsafePointer<UInt8>?
            var ppsHeader: UnsafePointer<UInt8>?
            
            CMVideoFormatDescriptionGetH264ParameterSetAtIndex(format, parameterSetIndex: 0, parameterSetPointerOut: &spsHeader, parameterSetSizeOut: &spsSize, parameterSetCountOut: &spsCount, nalUnitHeaderLengthOut: nil)
            
            CMVideoFormatDescriptionGetH264ParameterSetAtIndex(format, parameterSetIndex: 1, parameterSetPointerOut: &ppsHeader, parameterSetSizeOut: &ppsSize, parameterSetCountOut: &ppsCount, nalUnitHeaderLengthOut: nil)
            
            if let sps = spsHeader, let pps = ppsHeader {
                let startCode: [UInt8] = [0x00, 0x00, 0x00, 0x01]
                videoData.append(contentsOf: startCode)
                videoData.append(sps, count: spsSize)
                videoData.append(contentsOf: startCode)
                videoData.append(pps, count: ppsSize)
            }
        }
        
        guard let dataBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) else { return nil }
        
        var lengthAtOffset: Int = 0
        var totalLength: Int = 0
        var dataPointer: UnsafeMutablePointer<Int8>?
        
        guard CMBlockBufferGetDataPointer(dataBuffer, atOffset: 0, lengthAtOffsetOut: &lengthAtOffset, totalLengthOut: &totalLength, dataPointerOut: &dataPointer) == noErr else { return nil }
        
        var bufferOffset = 0
        let avccHeaderLength = 4
        
        while bufferOffset < totalLength - avccHeaderLength {
            var nalUnitLength: UInt32 = 0
            memcpy(&nalUnitLength, dataPointer! + bufferOffset, avccHeaderLength)
            nalUnitLength = CFSwapInt32BigToHost(nalUnitLength)
            
            let startCode: [UInt8] = [0x00, 0x00, 0x00, 0x01]
            videoData.append(contentsOf: startCode)
            
            videoData.append(UnsafeBufferPointer(start: UnsafePointer<UInt8>(OpaquePointer(dataPointer! + bufferOffset + avccHeaderLength)), count: Int(nalUnitLength)))
            
            bufferOffset += avccHeaderLength + Int(nalUnitLength)
        }
        return videoData
    }
}
