//
//  HEVCFrameSender.swift
//  mirroringBooth
//
//  Created by 최윤진 on 12/23/25.
//

import Foundation
import CoreImage
import CoreMedia
import QuartzCore

final class HEVCFrameSender {
    private let latestCiImageProvider: () -> CIImage?
    private let manager: MPCSessionManager
    private let sendQueue = DispatchQueue(label: "hevc.frame.sender.queue")

    private var encoder: HEVCEncoder?
    private var frameIndex: Int64 = 0

    private var lastSentTime: CFTimeInterval = 0
    private let minSendInterval: CFTimeInterval
    private var isEncodingOrSending = false

    private var currentEncoderWidth: Int32 = 0
    private var currentEncoderHeight: Int32 = 0

    private let bitrate: Int
    private let targetFrameRate: Int

    init(
        provider: @escaping () -> CIImage?,
        manager: MPCSessionManager,
        bitrate: Int = 2_000_000,
        targetFrameRate: Int = 30
    ) {
        self.latestCiImageProvider = provider
        self.manager = manager
        self.bitrate = bitrate
        self.targetFrameRate = targetFrameRate

        let safeFrameRate = max(1, targetFrameRate)
        self.minSendInterval = 1.0 / Double(safeFrameRate)
    }

    func tickSend() {
        self.sendQueue.async { [weak self] in
            guard let self,
                  self.manager.connectedPeers.isEmpty == false,
                  self.isEncodingOrSending == false else { return }

            let now = CACurrentMediaTime()
            let elapsed = now - self.lastSentTime
            guard self.minSendInterval <= elapsed else { return }

            guard let ciImage = self.latestCiImageProvider() else { return }

            let imageWidth = Int32(ciImage.extent.width)
            let imageHeight = Int32(ciImage.extent.height)

            if self.encoder == nil ||
                self.currentEncoderWidth != imageWidth ||
                self.currentEncoderHeight != imageHeight {
                self.setupEncoder(width: imageWidth, height: imageHeight)
            }

            self.lastSentTime = now
            self.isEncodingOrSending = true

            let presentationTimeStamp = CMTime(value: self.frameIndex, timescale: CMTimeScale(self.targetFrameRate))
            self.frameIndex += 1

            self.encoder?.encode(ciImage, presentationTimeStamp: presentationTimeStamp)
        }
    }

    func invalidate() {
        sendQueue.async { [weak self] in
            self?.encoder?.invalidate()
            self?.encoder = nil
            self?.currentEncoderWidth = 0
            self?.currentEncoderHeight = 0
        }
    }

    // MARK: - Private

    private func setupEncoder(width: Int32, height: Int32) {
        self.encoder?.invalidate()
        self.frameIndex = 0

        let newEncoder = HEVCEncoder(
            width: width,
            height: height,
            bitrate: bitrate,
            expectedFrameRate: targetFrameRate
        )

        newEncoder.setEncodedFrameHandler { [weak self] encodedData in
            guard let self else { return }
            self.manager.sendHEVCFrameData(encodedData)
            self.isEncodingOrSending = false
        }

        if newEncoder.prepareEncoder() {
            self.encoder = newEncoder
            self.currentEncoderWidth = width
            self.currentEncoderHeight = height
        }
    }
}
