//
//  StreamingStore.swift
//  mirroringBooth
//
//  Created by 윤대현 on 1/8/26.
//

import AVFoundation
import Foundation
import OSLog

@Observable
final class StreamingStore: StoreProtocol {
    // 오버레이 상태
    enum OverlayPhase: Identifiable {
        var id: Self { self }

        case none
        case guide // 가이드라인 오버레이
        case countdown // 8, 7, 6, 5, 4, 3, 2, 1 카운트다운
        case shooting // 촬영 중 (8초 간격)
        case transferring // 전송, 수신 중
        case poseSuggestion
        case completed // 촬영 완료
    }

    struct State {
        // 스트리밍
        var isStreaming: Bool = false
        var currentSampleBuffer: CMSampleBuffer?
        var rotationAngle: Int16 = Int16.zero

        // 오버레이
        var overlayPhase: [OverlayPhase]

        // 타이머
        var countdownValue: Int = 8     // 첫 촬영 전 카운트 다운
        var shootingCountdown: Int = 7  // 촬영 간격 카운트 다운
        var capturePhotoCount: Int = 0  // 현재 촬영 횟수
        var totalCaptureCount: Int = 10 // 총 촬영 횟수

        // 이미지 전송 프로그래스
        var receivedPhotoCount: Int = 0

        // 촬영효과
        var showCapturEffect: Bool = false

        // 추천할 포즈 목록
        var poseList: [Pose] = []
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

        // 캡쳐 효과
        case setShowCaptureEffect(Bool)

        // 포즈 기능
        case setPoseList([Pose])
    }

    enum Result {
        // 오버레이 페이즈 관리
        case phaseChanged(OverlayPhase)
        case phaseAppended(OverlayPhase)
        case phaseRemoved(OverlayPhase)

        // 스트리밍
        case streamingStarted
        case streamingStopped
        case videoFrameDecoded(CMSampleBuffer, Int16)

        // 타이머
        case countdownUpdated(Int)
        case shootingCountdownUpdated(Int)
        case capturePhotoCountUpdated(Int)

        // 사진 전송
        case receivedPhotoCountUpdated(Int)

        // 캡쳐 효과
        case setShowCaptureEffect(Bool)

        // 포즈 기능
        case setPoseList([Pose])
    }

    var state: State

    private let advertiser: Advertiser?
    private let decoder: H264Decoder
    private var timer: Timer?

    init(
        _ advertiser: Advertiser?,
        decoder: H264Decoder,
        initialPhase: OverlayPhase
    ) {
        self.advertiser = advertiser
        self.decoder = decoder
        self.state = State(overlayPhase: [initialPhase])

        decoder.onDecodedSampleBuffer = { [weak self] sampleBuffer, rotationAngle in
            Task { @MainActor in
                self?.reduce(.videoFrameDecoded(sampleBuffer, rotationAngle))
            }
        }

        guard let advertiser else {
            Logger.streamingStore.error("advertiser가 없어 정상 동작하지 않습니다.")
            return
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

        // 카메라 캡쳐 이펙트
        advertiser.onCaptureEffect = { [weak self] in
            self?.captureEffect()
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
            advertiser?.onReceivedStreamData = nil
            result.append(.streamingStopped)
            // MARK: - 타이머
        case .startCountdown:
            result.append(.phaseRemoved(.guide))
            result.append(.phaseAppended(.countdown))
            result.append(.countdownUpdated(8))
            startTimer()

        case .tick:
            result.append(contentsOf: handleTick())
            // MARK: - 사진 전송
        case .startTransfer:
            result.append(.phaseChanged(.transferring))
            advertiser?.sendCommand(.startTransfer)
            advertiser?.setupCacheManager()

        case .photoReceived:
            let newCount = state.receivedPhotoCount + 1
            result.append(.receivedPhotoCountUpdated(newCount))
            if newCount >= state.totalCaptureCount {
                advertiser?.stopHeartBeating()
                result.append(.phaseChanged(.completed))
            }

        case .capturePhotoCount:
            let newCount = min(state.totalCaptureCount, state.capturePhotoCount + 1)
            result.append(.capturePhotoCountUpdated(newCount))

        case .setShowCaptureEffect(let value):
            if state.capturePhotoCount < state.totalCaptureCount {
                result.append(.setShowCaptureEffect(value))
            }

        case .setPoseList(let poses):
            result.append(.setPoseList(poses))
            result.append(.phaseAppended(.poseSuggestion))
        }

        return result
    }

    func reduce(_ result: Result) {
        var state = self.state

        switch result {
        case .phaseChanged(let phase):
            state.overlayPhase = [phase]

        case .phaseAppended(let phase):
            state.overlayPhase.append(phase)

        case .phaseRemoved(let phase):
            guard let index = state.overlayPhase.firstIndex(of: phase) else { return }
            state.overlayPhase.remove(at: index)

            // MARK: - 스트리밍
        case .streamingStarted:
            state.isStreaming = true

        case .streamingStopped:
            state.isStreaming = false
            state.currentSampleBuffer = nil

        case .videoFrameDecoded(let sampleBuffer, let rotationAngle):
            state.currentSampleBuffer = sampleBuffer
            state.rotationAngle = rotationAngle
            // MARK: - 타이머
        case .countdownUpdated(let value):
            state.countdownValue = value

        case .shootingCountdownUpdated(let value):
            state.shootingCountdown = value

        case .capturePhotoCountUpdated(let count):
            state.capturePhotoCount = count

        case .receivedPhotoCountUpdated(let count):
            state.receivedPhotoCount = count

        case .setShowCaptureEffect(let value):
            state.showCapturEffect = value

        case .setPoseList(let poses):
            state.poseList = poses
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

        if state.overlayPhase.contains(.countdown) {
            if state.countdownValue > 1 {
                results.append(.countdownUpdated(state.countdownValue - 1))
            } else {
                results.append(.phaseRemoved(.countdown))
                results.append(.phaseAppended(.shooting))
                results.append(.shootingCountdownUpdated(7))
                capturePhoto() // 첫 촬영
            }
        } else if state.overlayPhase.contains(.shooting) {
            if state.shootingCountdown > 0 { // 7, 6, 5, 4, 3, 2, 1, 0
                results.append(.shootingCountdownUpdated(state.shootingCountdown - 1))
            } else {
                capturePhoto() // 0 일때 촬영하고 리셋
                // 10장 촬영 완료 시
                let currentCaptureCount = state.capturePhotoCount + 1

                if currentCaptureCount >= state.totalCaptureCount {
                    stopTimer()
                } else {
                    results.append(.shootingCountdownUpdated(7))
                }
            }
        }

        return results
    }

    private func capturePhoto() {
        Task { @MainActor [weak self] in
            self?.advertiser?.sendCommand(.capturePhoto)
        }
    }
}

// MARK: - 캡쳐 이펙트
extension StreamingStore {
    func captureEffect() {
        self.send(.setShowCaptureEffect(true))
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.send(.setShowCaptureEffect(false))
        }
    }
}
