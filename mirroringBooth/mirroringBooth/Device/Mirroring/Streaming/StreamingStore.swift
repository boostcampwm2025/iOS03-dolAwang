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
    // 오버레이 상태
    enum OverlayPhase {
        case none
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

        // 오버레이
        var overlayPhase: OverlayPhase

        // 타이머
        var countdownValue: Int = 8     // 첫 촬영 전 카운트 다운 (8, 7, 6, 5, 4, 3, 2, 1)
        var shootingCountdown: Int = 8  // 촬영 간격 카운트 다운 (8초마다)
        var capturePhotoCount: Int = 0       // 현재 촬영 횟수
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
        case capturePhotoCount  // 촬영 카운트 수신
    }

    enum Result {
        // 스트리밍
        case streamingStarted
        case streamingStopped
        case videoFrameDecoded(CMSampleBuffer)

        // 타이머
        case phaseChanged(OverlayPhase)
        case countdownUpdated(Int)
        case shootingCountdownUpdated(Int)
        case capturePhotoCountUpdated(Int)

        // 사진 전송
        case receivedPhotoCountUpdated(Int)
    }

    var state: State

    private let advertiser: Advertiser
    private let decoder: H264Decoder
    private var timer: Timer?

    init(
        _ advertiser: Advertiser,
        decoder: H264Decoder,
        initialPhase: OverlayPhase
    ) {
        self.advertiser = advertiser
        self.decoder = decoder
        self.state = State(overlayPhase: initialPhase)

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

        advertiser.onUpdateCaptureCount = { [weak self] in
            self?.send(.capturePhotoCount)
        }

        // 10장 사진 저장 시작
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
            advertiser.setupCacheManager()

        case .photoReceived:
            let newCount = state.receivedPhotoCount + 1
            result.append(.receivedPhotoCountUpdated(newCount))
            if newCount >= state.totalCaptureCount {
                advertiser.stopHeartBeating()
                result.append(.phaseChanged(.completed))
            }

        case .capturePhotoCount:
            let newCount = min(state.totalCaptureCount, state.capturePhotoCount + 1)
            result.append(.capturePhotoCountUpdated(newCount))
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
            state.overlayPhase = phase

        case .countdownUpdated(let value):
            state.countdownValue = value

        case .shootingCountdownUpdated(let value):
            state.shootingCountdown = value

        case .capturePhotoCountUpdated(let count):
            state.capturePhotoCount = count

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

        switch state.overlayPhase {
        case .countdown:
            if state.countdownValue > 1 {
                results.append(.countdownUpdated(state.countdownValue - 1))
            } else {
                results.append(.phaseChanged(.shooting))
                results.append(.shootingCountdownUpdated(8))

                capturePhoto()
            }
        case .shooting:
            if state.shootingCountdown > 1 {
                results.append(.shootingCountdownUpdated(state.shootingCountdown - 1))
            } else {
                capturePhoto()

                // 10장 촬영 완료 시
                if state.capturePhotoCount >= state.totalCaptureCount - 1 {
                    stopTimer()
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
