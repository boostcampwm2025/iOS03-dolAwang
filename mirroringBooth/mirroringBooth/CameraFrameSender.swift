//
//  CameraFrameSender.swift
//  mirroringBooth
//
//  Created by 최윤진 on 12/22/25.
//

import Foundation
import CoreImage
import QuartzCore

final class CameraFrameSender {
    private let latestCiImageProvider: () -> CIImage?
    private let manager: MPCSessionManager
    private let sendQueue = DispatchQueue(label: "camera.frame.sender.queue")

    private let ciContext = CIContext()

    private var lastSentTime: CFTimeInterval = 0
    private let minSendInterval: CFTimeInterval
    private var isEncodingOrSending: Bool = false

    init(
        provider: @escaping () -> CIImage?,
        manager: MPCSessionManager,
        targetFps: Int
    ) {
        self.latestCiImageProvider = provider
        self.manager = manager

        let safeTargetFps: Int = max(1, targetFps)
        self.minSendInterval = 1.0 / Double(safeTargetFps)
    }

    func tickSend() {
        self.sendQueue.async { [weak self] in
            guard let self = self,
                  self.manager.connectedPeers.isEmpty == false,
                  self.isEncodingOrSending == false else { return }

            let now = CACurrentMediaTime()
            let elapsed = now - self.lastSentTime
            guard self.minSendInterval <= elapsed else { return }

            guard let ciImage = self.latestCiImageProvider() else { return }

            self.lastSentTime = now
            self.isEncodingOrSending = true

            autoreleasepool {
                let colorSpace: CGColorSpace = CGColorSpaceCreateDeviceRGB()
                let options: [CIImageRepresentationOption: Any] = [
                    kCGImageDestinationLossyCompressionQuality as CIImageRepresentationOption: 0.2 as CGFloat
                ]

                guard let jpegDataValue: Data = self.ciContext.jpegRepresentation(
                    of: ciImage,
                    colorSpace: colorSpace,
                    options: options
                ) else {
                    self.isEncodingOrSending = false
                    return
                }

                self.manager.sendMjpegFrameData(jpegDataValue)
                self.isEncodingOrSending = false
            }
        }
    }
}
