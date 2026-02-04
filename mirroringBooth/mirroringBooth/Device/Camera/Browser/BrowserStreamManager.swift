//
//  BrowserStreamManager.swift
//  mirroringBooth
//
//  Created by 윤대현 on 2026-02-04.
//

import Foundation

/// Browser의 Stream과 Continuation을 관리하는 매니저
final class BrowserStreamManager {

    // MARK: - Browsing

    /// 기기 검색 및 연결 전용 이벤트 스트림
    let browsingEventStream: AsyncStream<BrowsingEvents>
    private let browsingEventContinuation: AsyncStream<BrowsingEvents>.Continuation

    // MARK: - Camera Stream

    /// 카메라 촬영 및 전송 전용 이벤트 스트림
    let cameraStreamEventStream: AsyncStream<CameraStreamEvents>
    private let cameraStreamEventContinuation: AsyncStream<CameraStreamEvents>.Continuation

    // MARK: - Heartbeat Streams

    /// BrowsingStore 전용 Heartbeat 스트림
    let browsingHeartbeatStream: AsyncStream<HeartBeatEvents>
    let browsingHeartbeatContinuation: AsyncStream<HeartBeatEvents>.Continuation

    /// ConnectionCheckStore 전용 Heartbeat 스트림
    let connectionCheckHeartbeatStream: AsyncStream<HeartBeatEvents>
    let connectionCheckHeartbeatContinuation: AsyncStream<HeartBeatEvents>.Continuation

    /// CameraPreviewStore 전용 Heartbeat 스트림
    let cameraPreviewHeartbeatStream: AsyncStream<HeartBeatEvents>
    let cameraPreviewHeartbeatContinuation: AsyncStream<HeartBeatEvents>.Continuation

    init() {
        (self.browsingEventStream, self.browsingEventContinuation) = AsyncStream.makeStream(
            of: BrowsingEvents.self
        )

        (self.cameraStreamEventStream, self.cameraStreamEventContinuation) = AsyncStream.makeStream(
            of: CameraStreamEvents.self,
            bufferingPolicy: .bufferingNewest(1)
        )

        (self.browsingHeartbeatStream, self.browsingHeartbeatContinuation) = AsyncStream.makeStream(
            of: HeartBeatEvents.self,
            bufferingPolicy: .bufferingNewest(1)
        )

        (self.connectionCheckHeartbeatStream, self.connectionCheckHeartbeatContinuation) = AsyncStream.makeStream(
            of: HeartBeatEvents.self,
            bufferingPolicy: .bufferingNewest(1)
        )

        (self.cameraPreviewHeartbeatStream, self.cameraPreviewHeartbeatContinuation) = AsyncStream.makeStream(
            of: HeartBeatEvents.self,
            bufferingPolicy: .bufferingNewest(1)
        )
    }

    func yieldBrowsingEvent(_ event: BrowsingEvents) {
        browsingEventContinuation.yield(event)
    }

    func yieldCameraStreamEvent(_ event: CameraStreamEvents) {
        cameraStreamEventContinuation.yield(event)
    }

    func yieldHeartbeatTimeoutToAll() {
        browsingHeartbeatContinuation.yield(.heartbeatTimeout)
        connectionCheckHeartbeatContinuation.yield(.heartbeatTimeout)
        cameraPreviewHeartbeatContinuation.yield(.heartbeatTimeout)
    }

    func yieldRemoteHeartbeatTimeoutToAll() {
        browsingHeartbeatContinuation.yield(.remoteHeartbeatTimeout)
        connectionCheckHeartbeatContinuation.yield(.remoteHeartbeatTimeout)
        cameraPreviewHeartbeatContinuation.yield(.remoteHeartbeatTimeout)
    }
}
