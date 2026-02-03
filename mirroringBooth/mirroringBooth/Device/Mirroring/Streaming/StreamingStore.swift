//
//  StreamingStore.swift
//  mirroringBooth
//
//  Created by 윤대현 on 1/8/26.
//

import AVFoundation
import OSLog
import SwiftUI

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

        // 포즈 제안
        var poseList: [Pose] = []
        var currentSuggestedPoses: [Pose] {
            Array(poseList.prefix(2))
        }

        // 그 외
        var showHomeAlert: Bool = false     //  얼럿
        var videoViewSize: CGSize = .zero   // 비디오 뷰 크기
        var colorScheme: ColorScheme?
    }

    enum Intent {
        // 화면 접근
        case entry(with: [Pose])
        case exit

        // 타이머 모드
        case startCountdown // "준비 완료" 버튼 클릭 시
        case tick           // 1초마다 호출

        // 사진 전송
        case startTransfer // 전송 시작
        case photoReceived // 사진 1장 수신
        case capturePhotoCount  // 촬영 카운트 수신

        // 캡쳐 효과
        case setShowCaptureEffect(Bool)

        // 그 외
        case setHomeAlert(Bool)
        case setVideoViewSize(CGSize)
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
        case removePose

        // 그 외
        case setHomeAlert(Bool)
        case setVideoViewSize(CGSize)
        case setColorScheme(ColorScheme?)
    }

    private(set) var state: State
    let isTimerMode: Bool

    private let advertiser: Advertiser?
    private let decoder: H264Decoder
    private var timer: Timer?
    private var streamingTask: Task<Void, Never>?
    private var commandTask: Task<Void, Never>?

    init(
        _ advertiser: Advertiser?,
        decoder: H264Decoder,
        isTimerMode: Bool
    ) {
        self.isTimerMode = isTimerMode
        self.advertiser = advertiser
        self.decoder = decoder
        self.state = State(overlayPhase: [isTimerMode ? .guide : .none])

        decoder.onDecodedSampleBuffer = { [weak self] sampleBuffer, rotationAngle in
            Task { @MainActor in
                self?.reduce(.videoFrameDecoded(sampleBuffer, rotationAngle))
            }
        }
        startListening()
    }

    func action(_ intent: Intent) -> [Result] {
        var result: [Result] = []

        switch intent {
            // MARK: - 화면 접근
        case .entry(let poseList):
            if !poseList.isEmpty {
                result.append(.phaseAppended(.poseSuggestion))
            }
            result.append(.setColorScheme(.dark))
            result.append(.streamingStarted)
            result.append(.setPoseList(poseList))

        case .exit:
            decoder.stop()
            result.append(.setColorScheme(nil))
            streamingTask?.cancel()
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
            result.append(.removePose)

        case .setShowCaptureEffect(let value):
            if state.capturePhotoCount < state.totalCaptureCount {
                result.append(.setShowCaptureEffect(value))
            }

        case .setHomeAlert(let value):
            result.append(.setHomeAlert(value))

        case .setVideoViewSize(let value):
            result.append(.setVideoViewSize(value))
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

        case .removePose:
            if !state.poseList.isEmpty {
                state.poseList.removeFirst()
            }

        case .setHomeAlert(let value):
            state.showHomeAlert = value

        case .setVideoViewSize(let size):
            state.videoViewSize = size

        case .setColorScheme(let scheme):
            state.colorScheme = scheme
        }

        self.state = state
    }
}

// MARK: Stream Listner
extension StreamingStore {
    private func startListening() {
        guard let advertiser else { return }
        streamingTask = Task { [weak self] in
            for await stream in advertiser.videoStream {
                if case .streamDataReceived(let data) = stream {
                    self?.decoder.decode(data)
                }
            }
        }
        commandTask = Task { @MainActor [weak self] in
            for await stream in advertiser.streamingStoreStream {
                switch stream {
                case .onPhotoReceived:
                    self?.send(.photoReceived)
                case .onUpdateCaptureCount:
                    self?.send(.capturePhotoCount)
                case .onStoreAllPhotos:
                    self?.send(.startTransfer)
                case .onCaptureEffect:
                    self?.captureEffect()
                }
            }
        }
    }
}

// MARK: - 타이머 모드 로직
extension StreamingStore {
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.send(.tick)
            }
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
        advertiser?.sendCommand(.capturePhoto)
    }
}

// MARK: - 캡쳐 이펙트
extension StreamingStore {
    @MainActor
    func captureEffect() {
        self.send(.setShowCaptureEffect(true))
        Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 200_000_000)
            self?.send(.setShowCaptureEffect(false))
        }
    }
}
