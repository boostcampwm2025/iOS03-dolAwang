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

    // 타이머 촬영 단계를 구분하기 위한 enum
    enum TimerPhase {
        case guide // 가이드라인 오버레이
        case countdown // 5, 4, 3, 2, 1 카운트다운
        case shooting // 촬영 중 (5초 간격)
        case completed // 촬영 완료
    }

    struct State {
        // 스트리밍
        var isStreaming: Bool = false
        var currentSampleBuffer: CMSampleBuffer?

        // 타이머
        var timerPhase: TimerPhase = .guide
        var countdownValue: Int = 5     // 첫 촬영 전 카운트 다운 (5, 4, 3, 2, 1)
        var shootingCountdown: Int = 5  // 촬영 간격 카운트 다운 (5초마다)
        var captureCount: Int = 0       // 현재 촬영 횟수
        var totalCaptureCount: Int = 12 // 총 촬영 횟수
    }

    enum Intent {
        // 스트리밍
        case startStreaming
        case stopStreaming

        // 타이머 모드
        case startCountdown // "준비 완료" 버튼 클릭 시
        case tick // 1초마다 호출
    }

    enum Result {
        // 스트리밍
        case streamingStarted
        case streamingStopped
        case videoFrameDecoded(CMSampleBuffer)

        // 타이머
        case phaseChanged(TimerPhase)
        case countdownUpdated(Int)
        case shootingCountdownUpdated(Int)
        case captureCountUpdated(Int)
    }

    var state: State = .init()

    private let advertiser: Advertisier
    private let decoder: H264Decoder
    private var timer: Timer?

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
            // MARK: - 스트리밍
        case .startStreaming:
            result.append(.streamingStarted)
        case .stopStreaming:
            decoder.stop()
            advertiser.onReceivedStreamData = nil
            result.append(.streamingStopped)
            // MARK: - 타이머
        case .startCountdown:
            result.append(.phaseChanged(.countdown))
            result.append(.countdownUpdated(5))
            startTimer()

        case .tick:
            result.append(contentsOf: handleTick())
        }

        return result
    }

    func reduce(_ result: Result) {
        var state = self.state

        switch result {
            // MARK: - 스트리밍
        case .streamingStarted:
            state.isStreaming = true

        case .streamingStopped:
            state.isStreaming = false
            state.currentSampleBuffer = nil

        case .videoFrameDecoded(let sampleBuffer):
            state.currentSampleBuffer = sampleBuffer
            // MARK: - 타이머
        case .phaseChanged(let phase):
            state.timerPhase = phase

        case .countdownUpdated(let value):
            state.countdownValue = value

        case .shootingCountdownUpdated(let value):
            state.shootingCountdown = value

        case .captureCountUpdated(let count):
            state.captureCount = count
        }

        self.state = state
    }
}

// MARK: - 타이머 모드 로직
extension StreamingStore {
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.send(.tick)
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func handleTick() -> [Result] {
        var results: [Result] = []

        switch state.timerPhase {
        case .countdown:
            if state.countdownValue > 1 {
                results.append(.countdownUpdated(state.countdownValue - 1))
            } else {
                // 5초 카운트다운 완료 후 촬영 시작
                results.append(.phaseChanged(.shooting))
                results.append(.shootingCountdownUpdated(5))
                capturePhoto()
                results.append(.captureCountUpdated(state.captureCount + 1))
            }
        case .shooting:
            if state.shootingCountdown > 1 {
                results.append(.shootingCountdownUpdated(state.shootingCountdown - 1))
            } else {
                // 5초가 경과하면 촬영
                capturePhoto()
                let newCount = state.captureCount + 1
                results.append(.captureCountUpdated(newCount))

                if newCount >= state.totalCaptureCount {
                    // 12장 완료
                    stopTimer()
                    results.append(.phaseChanged(.completed))
                } else {
                    results.append(.shootingCountdownUpdated(5))
                }
            }
        default:
            break
        }

        return results
    }

    private func capturePhoto() {
        advertiser.sendCommand(.capturePhoto)
    }
}
