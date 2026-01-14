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
        case countdown // 8, 7, 6, 5, 4, 3, 2, 1 카운트다운
        case shooting // 촬영 중 (8초 간격)
        case transferring // 전송, 수신 중
        case completed // 촬영 완료
    }

    struct State {
        // 스트리밍
        var isStreaming: Bool = false
        var currentSampleBuffer: CMSampleBuffer?

        // 타이머
        var timerPhase: TimerPhase = .guide
        var countdownValue: Int = 8     // 첫 촬영 전 카운트 다운 (8, 7, 6, 5, 4, 3, 2, 1)
        var shootingCountdown: Int = 8  // 촬영 간격 카운트 다운 (8초마다)
        var captureCount: Int = 0       // 현재 촬영 횟수
        var totalCaptureCount: Int = 10 // 총 촬영 횟수

        // 이미지 전송 프로그래스
        var receivedPhotoCount: Int = 0
    }

    enum Intent {
        // 스트리밍
        case startStreaming
        case stopStreaming

        // 타이머 모드
        case startCountdown // "준비 완료" 버튼 클릭 시
        case tick           // 1초마다 호출

        // 사진 전송
        case startTransfer // 전송 시작
        case photoReceived // 사진 1장 수신
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

        // 사진 전송
        case receivedPhotoCountUpdated(Int)
    }

    var state: State = .init()

    private let advertiser: Advertiser
    private let decoder: H264Decoder
    private var timer: Timer?

    init(_ advertiser: Advertiser, decoder: H264Decoder) {
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

        // 사진 수신 콜백
        advertiser.onPhotoReceived = { [weak self] in
            self?.send(.photoReceived)
        }

        // 10장 모두 저장 완료 콜백 (iPhone에서 전송)
        advertiser.onAllPhotosStored = { [weak self] in
            self?.send(.startTransfer)
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
            result.append(.countdownUpdated(8))
            startTimer()

        case .tick:
            result.append(contentsOf: handleTick())
            // MARK: - 사진 전송
        case .startTransfer:
            result.append(.phaseChanged(.transferring))
            advertiser.sendCommand(.startTransfer)

        case .photoReceived:
            let newCount = state.receivedPhotoCount + 1
            result.append(.receivedPhotoCountUpdated(newCount))
            if newCount >= state.totalCaptureCount {
                result.append(.phaseChanged(.completed))
            }
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

        case .receivedPhotoCountUpdated(let count):
            state.receivedPhotoCount = count
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
                // 8초 카운트다운 완료 후 첫 촬영
                results.append(.phaseChanged(.shooting))
                results.append(.shootingCountdownUpdated(8))

                capturePhoto()

                // 첫 촬영 시 captureCount를 먼저 업데이트
                let firstCount = state.captureCount + 1
                results.append(.captureCountUpdated(firstCount))
            }
        case .shooting:
            if state.shootingCountdown > 1 {
                results.append(.shootingCountdownUpdated(state.shootingCountdown - 1))
            } else {
                // 8초가 경과하면 촬영 (첫 촬영 후 8초마다)
                capturePhoto()

                let newCount = state.captureCount + 1
                results.append(.captureCountUpdated(newCount))

                // 10장 촬영 완료 시
                if newCount >= state.totalCaptureCount {
                    stopTimer()
                    results.append(.phaseChanged(.transferring))
                } else {
                    // 다음 촬영을 위한 카운트다운 재설정
                    results.append(.shootingCountdownUpdated(8))
                }
            }
        default:
            break
        }

        return results
    }

    private func capturePhoto() {
        Task { @MainActor [weak self] in
            self?.advertiser.sendCommand(.capturePhoto)
        }
    }
}
