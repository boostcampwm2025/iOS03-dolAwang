//
//  StreamManager.swift
//  mirroringBooth
//
//  Created by Liam on 2/3/26.
//

import Foundation

final class StreamManager {
    // MARK: - Continuations
    private let videoContinuation: AsyncStream<FrameReceivingEvents>.Continuation
    private let advertisingContinuation: AsyncStream<AdvertiserEvents>.Continuation
    private let modeSelectionContinuation: AsyncStream<ModeSelectionEvents>.Continuation
    private let remoteConnectedViewContinuation: AsyncStream<RemoteConnectedViewEvents>.Continuation
    private let remoteCaptureViewContinuation: AsyncStream<RemoteCaptureViewEvents>.Continuation
    private let streamingStoreContinuation: AsyncStream<StreamingStoreEvents>.Continuation
    private let rootContinuation: AsyncStream<RootEvents>.Continuation

    // MARK: - Streams (Public Access)
    let videoStream: AsyncStream<FrameReceivingEvents>
    let advertisingStream: AsyncStream<AdvertiserEvents>
    let modeSelectionStream: AsyncStream<ModeSelectionEvents>
    let remoteConnectedViewStream: AsyncStream<RemoteConnectedViewEvents>
    let remoteCaptureViewStream: AsyncStream<RemoteCaptureViewEvents>
    let streamingStoreStream: AsyncStream<StreamingStoreEvents>
    let rootStream: AsyncStream<RootEvents>

    init() {
        (videoStream, videoContinuation) = AsyncStream.makeStream(
            of: FrameReceivingEvents.self,
            bufferingPolicy: .bufferingNewest(1)
        )
        (advertisingStream, advertisingContinuation) = AsyncStream.makeStream(of: AdvertiserEvents.self)
        (modeSelectionStream, modeSelectionContinuation) = AsyncStream.makeStream(of: ModeSelectionEvents.self)
        (remoteConnectedViewStream, remoteConnectedViewContinuation) = AsyncStream.makeStream(
            of: RemoteConnectedViewEvents.self
        )
        (remoteCaptureViewStream, remoteCaptureViewContinuation) = AsyncStream.makeStream(
            of: RemoteCaptureViewEvents.self
        )
        (streamingStoreStream, streamingStoreContinuation) = AsyncStream.makeStream(of: StreamingStoreEvents.self)
        (rootStream, rootContinuation) = AsyncStream.makeStream(of: RootEvents.self)
    }

    // MARK: - Yield Methods
    func yieldVideo(_ data: Data) {
        videoContinuation.yield(.streamDataReceived(data))
    }

    func yieldAdvertising(_ event: AdvertiserEvents) {
        advertisingContinuation.yield(event)
    }

    func yieldModeSelection(_ event: ModeSelectionEvents) {
        modeSelectionContinuation.yield(event)
    }

    func yieldRemoteConnectedView(_ event: RemoteConnectedViewEvents) {
        remoteConnectedViewContinuation.yield(event)
    }

    func yieldRemoteCaptureView(_ event: RemoteCaptureViewEvents) {
        remoteCaptureViewContinuation.yield(event)
    }

    func yieldStreamingStore(_ event: StreamingStoreEvents) {
        streamingStoreContinuation.yield(event)
    }

    func yieldRoot(_ event: RootEvents) {
        rootContinuation.yield(event)
    }
}
