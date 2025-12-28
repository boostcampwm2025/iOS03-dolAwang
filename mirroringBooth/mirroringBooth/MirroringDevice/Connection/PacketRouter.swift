//
//  PacketRouter.swift
//  mirroringBooth
//
//  Created by 이상유 on 2025-12-29.
//

import Foundation
import Combine

/// 수신된 패킷을 타입에 따라 적절한 핸들러로 라우팅하는 클래스
final class PacketRouter {

    private let videoDecoder: VideoDecoder
    private let viewModel: StreamDisplayViewModel

    init(videoDecoder: VideoDecoder, viewModel: StreamDisplayViewModel) {
        self.videoDecoder = videoDecoder
        self.viewModel = viewModel

        setupCallbacks()
    }

    private func setupCallbacks() {
        // 디코더로부터 프레임을 받아 ViewModel로 전달
        videoDecoder.onDecodedFrame = { [weak viewModel] pixelBuffer in
            viewModel?.handleDecodedFrame(pixelBuffer)
        }
    }

    /// 수신된 패킷을 타입별로 라우팅
    func routePacket(_ data: Data) {
        guard let packet = DataPacket.deserialize(data) else {
            print("Failed to deserialize packet")
            return
        }

        switch packet.type {
        case .photo:
            // 고화질 사진 패킷 → ViewModel로 전달
            viewModel.handleReceivedPhoto(packet.data)

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
