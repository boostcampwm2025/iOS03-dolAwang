//
//  StreamingStore.swift
//  mirroringBooth
//
//  Created by 윤대현 on 1/8/26.
//

import AVFoundation
import Foundation

@Observable
final class StreamingStore: StoreProtocol {

    struct State {
        var isStreaming: Bool = false
        var currentSampleBuffer: CMSampleBuffer?
    }

    enum Intent {
        case startStreaming
        case stopStreaming
    }

    enum Result {
        case streamingStarted
        case streamingStopped
        case videoFrameDecoded(CMSampleBuffer)
    }

    var state: State = .init()

    private let advertiser: Advertisier
    private let decoder: H264Decoder

    init(_ advertiser: Advertisier, decoder: H264Decoder) {
        self.advertiser = advertiser
        self.decoder = decoder

        decoder.onDecodedSampleBuffer = { [weak self] sampleBuffer in
            Task { @MainActor in
                self?.reduce(.videoFrameDecoded(sampleBuffer))
            }
        }

        advertiser.onReceivedStreamData = { [weak self] data in
            self?.decoder.decode(data)
        }
    }

    func action(_ intent: Intent) -> [Result] {
        var result: [Result] = []

        switch intent {
        case .startStreaming:
            result.append(.streamingStarted)

        case .stopStreaming:
            decoder.stop()
            advertiser.onReceivedStreamData = nil
            result.append(.streamingStopped)
        }

        return result
    }

    func reduce(_ result: Result) {
        var state = self.state

        switch result {
        case .streamingStarted:
            state.isStreaming = true

        case .streamingStopped:
            state.isStreaming = false
            state.currentSampleBuffer = nil

        case .videoFrameDecoded(let sampleBuffer):
            state.currentSampleBuffer = sampleBuffer
        }

        self.state = state
    }
}
