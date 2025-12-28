//
//  PacketHandler.swift
//  mirroringBooth
//
//  Created by 이상유 on 2025-12-29.
//

import Foundation
import Combine

/// 수신된 패킷을 타입에 따라 적절한 핸들러로 전달하는 클래스
final class PacketHandler {

    private let videoDecoder: VideoDecoder
    private let renderer: MediaFrameRenderer

    /// 사진 데이터 수신 콜백
    var onPhotoReceived: ((Data) -> Void)?

    init(videoDecoder: VideoDecoder, renderer: MediaFrameRenderer) {
        self.videoDecoder = videoDecoder
        self.renderer = renderer

        setupCallbacks()
    }

    private func setupCallbacks() {
        // 디코더로부터 프레임을 받아 렌더러로 전달
        videoDecoder.onDecodedFrame = { [weak renderer] pixelBuffer in
            renderer?.renderDecodedFrame(pixelBuffer)
        }
    }

    /// 수신된 패킷을 타입별로 처리
    func handlePacket(_ data: Data) {
        guard let packet = MediaPacket.deserialize(data) else {
            print("Failed to deserialize packet")
            return
        }

        switch packet.type {
        case .photo:
            // 고화질 사진 패킷 → 콜백으로 직접 전달
            onPhotoReceived?(packet.data)

        case .sps, .pps, .idrFrame, .pFrame:
            // 비디오 스트리밍 패킷 → VideoDecoder로 전달
            videoDecoder.handleReceivedPacket(data)

        case .captureRequest:
            // 촬영 요청 패킷은 송신 측에서만 처리하므로 무시
            break
        }
    }

    func cleanup() {
        videoDecoder.cleanup()
    }

}
