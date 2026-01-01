//
//  H264Decoder.swift
//  mirroringBooth
//
//  Created by Liam on 1/1/26.
//

import Foundation
import OSLog
import VideoToolbox

protocol H264DecoderDelegate: AnyObject {
    func decoder(_ decoder: H264Decoder, didDecode imageBuffer: CVImageBuffer)
}

class H264Decoder {
    weak var delegate: H264DecoderDelegate?
    
    private var formatDescription: CMVideoFormatDescription?
    private var decompressionSession: VTDecompressionSession?
    
    private var sps: [UInt8]?
    private var pps: [UInt8]?
    
    private let startCode: [UInt8] = [0x00, 0x00, 0x00, 0x01]
    
    func decode(payload: Data) {
        var offset = 0
        let length = payload.count
        
        while offset < length {
            var nextOffset = length
            
            if let range = payload.range(of: Data(startCode), options: [], in: (offset + 4)..<length) {
                nextOffset = range.lowerBound
            }
            
            let nalUnitData = payload.subdata(in: offset..<nextOffset)
            processNALUnit(nalUnitData)
            
            offset = nextOffset
        }
    }
    
    private func processNALUnit(_ data: Data) {
        var data = data

        guard data.count > 4 else { return }
        let header = data[4]
        let nalType = header & 0x1F
        
        switch nalType {
        case 7: // SPS
            sps = Array(data.dropFirst(4))
            
        case 8: // PPS
            pps = Array(data.dropFirst(4))
            
        case 5: // IDR
            if let sps = sps, let pps = pps, decompressionSession == nil {
                createDecompressionSession(sps: sps, pps: pps)
            }
            decodeFrame(data: data)
            
        case 1: // Slice
            if decompressionSession != nil {
                decodeFrame(data: data)
            }
            
        default:
            break
        }
    }
    
    private func createDecompressionSession(sps: [UInt8], pps: [UInt8]) {
        let pointerSPS = UnsafePointer<UInt8>(sps)
        let pointerPPS = UnsafePointer<UInt8>(pps)
        
        let parameterSets = [pointerSPS, pointerPPS]
        let parameterSetSizes = [sps.count, pps.count]
        
        var status = CMVideoFormatDescriptionCreateFromH264ParameterSets(
            allocator: kCFAllocatorDefault,
            parameterSetCount: 2,
            parameterSetPointers: parameterSets,
            parameterSetSizes: parameterSetSizes,
            nalUnitHeaderLength: 4,
            formatDescriptionOut: &formatDescription
        )
        
        guard status == noErr, let format = formatDescription else {
            return
        }
        
        var sessionAttributes: [NSObject: AnyObject] = [
            kCVPixelBufferPixelFormatTypeKey as NSObject: Int(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange) as AnyObject,
            kCVPixelBufferMetalCompatibilityKey as NSObject: true as AnyObject
        ]
        
        var outputCallback = VTDecompressionOutputCallbackRecord(
            decompressionOutputCallback: decompressionCallback,
            decompressionOutputRefCon: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        )
        
        status = VTDecompressionSessionCreate(
            allocator: kCFAllocatorDefault,
            formatDescription: format,
            decoderSpecification: nil,
            imageBufferAttributes: sessionAttributes as CFDictionary,
            outputCallback: &outputCallback,
            decompressionSessionOut: &decompressionSession
        )
        
        if status != noErr {
            Logger.h264decoder.debug("🚨 디코더 준비 실패!")
        } else {
            Logger.h264decoder.debug("✅ 디코더 준비 완료!")
        }
    }
    
    private func decodeFrame(data: Data) {
        guard let session = decompressionSession,
              let format = formatDescription else { return }
        
        var data = data
        let length = UInt32(data.count - 4)
        var bigEndianLength = CFSwapInt32HostToBig(length)
        
        data.replaceSubrange(0..<4, with: withUnsafeBytes(of: bigEndianLength) { Data($0) })
    
        var blockBuffer: CMBlockBuffer?
        
        let imageBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: data.count)
        data.copyBytes(to: imageBuffer, count: data.count)
        
        let status = CMBlockBufferCreateWithMemoryBlock(
            allocator: kCFAllocatorDefault,
            memoryBlock: imageBuffer,
            blockLength: data.count,
            blockAllocator: kCFAllocatorDefault,
            customBlockSource: nil,
            offsetToData: 0,
            dataLength: data.count,
            flags: 0,
            blockBufferOut: &blockBuffer
        )
        
        guard status == noErr, let buffer = blockBuffer else { return }
        
        var sampleBuffer: CMSampleBuffer?
        var sampleSizeArray = [data.count]
        
        let sampleBufferStatus = CMSampleBufferCreateReady(
            allocator: kCFAllocatorDefault,
            dataBuffer: buffer,
            formatDescription: format,
            sampleCount: 1,
            sampleTimingEntryCount: 0,
            sampleTimingArray: nil,
            sampleSizeEntryCount: 1,
            sampleSizeArray: &sampleSizeArray,
            sampleBufferOut: &sampleBuffer
        )
        
        guard sampleBufferStatus == noErr, let sampleBuf = sampleBuffer else { return }
        
        var infoFlags = VTDecodeInfoFlags(rawValue: 0)
        
        VTDecompressionSessionDecodeFrame(
            session,
            sampleBuffer: sampleBuf,
            flags: [._EnableAsynchronousDecompression],
            frameRefcon: nil,
            infoFlagsOut: &infoFlags
        )
    }
}

private func decompressionCallback(
    outputRefCon: UnsafeMutableRawPointer?,
    sourceFrameRefCon: UnsafeMutableRawPointer?,
    status: OSStatus,
    infoFlags: VTDecodeInfoFlags,
    imageBuffer: CVImageBuffer?,
    presentationTimeStamp: CMTime,
    duration: CMTime
) {
    guard status == noErr, let image = imageBuffer, let context = outputRefCon else { return }
    
    let decoder = Unmanaged<H264Decoder>.fromOpaque(context).takeUnretainedValue()
    decoder.delegate?.decoder(decoder, didDecode: image)
}
