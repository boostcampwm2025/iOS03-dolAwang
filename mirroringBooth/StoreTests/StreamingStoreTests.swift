//
//  StreamingStoreTests.swift
//  StoreTests
//
//  Created by 이상유 on 2026-02-02.
//

import CoreMedia
import Testing
import SwiftUI
@testable import mirroringBooth

@MainActor
struct StreamingStoreTests {

    // MARK: - Helper

    private func makeSUT(
        isTimerMode: Bool = false
    ) -> StreamingStore {
        StreamingStore(
            nil,
            decoder: H264Decoder(),
            isTimerMode: isTimerMode
        )
    }

    private func makePoseList(count: Int = 3) -> [Pose] {
        (0..<count).map { i in
            Pose(emoji: "🧍", description: "포즈\(i)", summary: "요약\(i)")
        }
    }

    // MARK: - 화면 진입 (entry)

    @Test func 진입하면_스트리밍이_시작됨() {
        let store = makeSUT()

        store.send(.entry(with: []))

        #expect(store.state.isStreaming == true)
    }

    @Test func 진입하면_다크모드로_설정됨() {
        let store = makeSUT()

        store.send(.entry(with: []))

        #expect(store.state.colorScheme == .dark)
    }

    @Test func 포즈_리스트와_함께_진입하면_포즈_제안_오버레이가_추가됨() {
        let store = makeSUT()
        let poses = makePoseList()

        store.send(.entry(with: poses))

        #expect(store.state.overlayPhase.contains(.poseSuggestion))
    }

    @Test func 포즈_리스트와_함께_진입하면_포즈가_저장됨() {
        let store = makeSUT()
        let poses = makePoseList(count: 5)

        store.send(.entry(with: poses))

        #expect(store.state.poseList.count == 5)
    }

    @Test func 빈_포즈_리스트로_진입하면_포즈_제안_오버레이가_없음() {
        let store = makeSUT()

        store.send(.entry(with: []))

        #expect(!store.state.overlayPhase.contains(.poseSuggestion))
    }

    @Test func 현재_제안_포즈는_최대_2개까지_표시됨() {
        let store = makeSUT()
        let poses = makePoseList(count: 5)

        store.send(.entry(with: poses))

        #expect(store.state.currentSuggestedPoses.count == 2)
    }

    // MARK: - 화면 퇴장 (exit)

    @Test func 퇴장하면_스트리밍이_중지됨() {
        let store = makeSUT()
        store.send(.entry(with: []))

        store.send(.exit)

        #expect(store.state.isStreaming == false)
    }

    @Test func 퇴장하면_설정이_초기화됨() {
        let store = makeSUT()
        store.send(.entry(with: []))

        store.send(.exit)

        #expect(store.state.currentSampleBuffer == nil)
        #expect(store.state.colorScheme == nil)
    }

    // MARK: - 카운트다운 시작 (startCountdown)

    @Test func 준비완료_버튼을_누르면_가이드_오버레이가_제거됨() {
        let store = makeSUT(isTimerMode: true)

        store.send(.startCountdown)

        #expect(!store.state.overlayPhase.contains(.guide))
    }

    @Test func 준비완료_버튼을_누르면_카운트다운_오버레이가_추가됨() {
        let store = makeSUT(isTimerMode: true)

        store.send(.startCountdown)

        #expect(store.state.overlayPhase.contains(.countdown))
    }

    @Test func 준비완료_버튼을_누르면_카운트다운이_8로_설정됨() {
        let store = makeSUT(isTimerMode: true)

        store.send(.startCountdown)

        #expect(store.state.countdownValue == 8)
    }

    // MARK: - 카운트다운 틱 (tick)

    @Test func 카운트다운_중_틱이_오면_값이_1_감소함() {
        let store = makeSUT(isTimerMode: true)
        store.send(.startCountdown) // countdown = 8

        store.send(.tick) // countdown = 7

        #expect(store.state.countdownValue == 7)
    }

    @Test func 카운트다운이_1일때_틱이_오면_촬영_모드로_전환됨() {
        let store = makeSUT(isTimerMode: true)
        store.send(.startCountdown)
        // 카운트다운을 1까지 내림
        for _ in 0..<7 { store.send(.tick) }
        #expect(store.state.countdownValue == 1)

        store.send(.tick)

        #expect(!store.state.overlayPhase.contains(.countdown))
        #expect(store.state.overlayPhase.contains(.shooting))
        #expect(store.state.shootingCountdown == 7)
    }

    @Test func 촬영_모드에서_틱이_오면_촬영간격_카운트다운이_감소함() {
        let store = makeSUT(isTimerMode: true)
        store.send(.startCountdown)
        for _ in 0..<8 { store.send(.tick) } // 촬영 모드 진입, shootingCountdown = 7

        store.send(.tick)

        #expect(store.state.shootingCountdown == 6)
    }

    @Test func 촬영간격_카운트다운이_0이면_촬영후_7로_리셋됨() {
        let store = makeSUT(isTimerMode: true)
        store.send(.startCountdown)
        for _ in 0..<8 { store.send(.tick) } // 촬영 모드 진입
        for _ in 0..<7 { store.send(.tick) } // shootingCountdown → 0

        store.send(.tick) // 0일 때 촬영 + 리셋

        #expect(store.state.shootingCountdown == 7)
    }

    // MARK: - 사진 전송 (startTransfer)

    @Test func 전송이_시작되면_전송중_오버레이로_변경됨() {
        let store = makeSUT()

        store.send(.startTransfer)

        #expect(store.state.overlayPhase == [.transferring])
    }

    // MARK: - 사진 수신 (photoReceived)

    @Test func 사진_1장_수신되면_수신_카운트가_증가함() {
        let store = makeSUT()

        store.send(.photoReceived)

        #expect(store.state.receivedPhotoCount == 1)
    }

    @Test func 사진이_연속으로_수신되면_카운트가_누적됨() {
        let store = makeSUT()

        store.send(.photoReceived)
        store.send(.photoReceived)
        store.send(.photoReceived)

        #expect(store.state.receivedPhotoCount == 3)
    }

    @Test func 모든_사진이_수신되면_완료_오버레이로_변경됨() {
        let store = makeSUT()
        for _ in 0..<9 { store.send(.photoReceived) }

        store.send(.photoReceived) // 10번째

        #expect(store.state.overlayPhase == [.completed])
    }

    // MARK: - 촬영 카운트 수신 (capturePhotoCount)

    @Test func 촬영_카운트_수신되면_촬영_횟수가_증가함() {
        let store = makeSUT()

        store.send(.capturePhotoCount)

        #expect(store.state.capturePhotoCount == 1)
    }

    @Test func 촬영_카운트는_총_촬영_횟수를_초과하지_않음() {
        let store = makeSUT()
        for _ in 0..<10 { store.send(.capturePhotoCount) }

        store.send(.capturePhotoCount) // 11번째

        #expect(store.state.capturePhotoCount == 10)
    }

    @Test func 촬영_카운트_수신_시_포즈가_하나_제거됨() {
        let store = makeSUT()
        let poses = makePoseList(count: 3)
        store.send(.entry(with: poses))

        store.send(.capturePhotoCount)

        #expect(store.state.poseList.count == 2)
    }

    @Test func 포즈가_비어있을때_촬영_카운트_수신해도_크래시_안함() {
        let store = makeSUT()
        store.send(.entry(with: []))

        store.send(.capturePhotoCount)

        #expect(store.state.poseList.isEmpty)
    }

    // MARK: - 캡쳐 효과 (setShowCaptureEffect)

    @Test func 캡쳐_효과가_켜짐() {
        let store = makeSUT()

        store.send(.setShowCaptureEffect(true))

        #expect(store.state.showCapturEffect == true)
    }

    @Test func 촬영이_모두_완료되면_캡쳐_효과가_무시됨() {
        let store = makeSUT()
        for _ in 0..<10 { store.send(.capturePhotoCount) }

        store.send(.setShowCaptureEffect(true))

        #expect(store.state.showCapturEffect == false)
    }

    // MARK: - 홈 알림 (setHomeAlert)

    @Test func 연결끊기_버튼을_누르면_홈_알림이_표시됨() {
        let store = makeSUT()

        store.send(.setHomeAlert(true))

        #expect(store.state.showHomeAlert == true)
    }

    // MARK: - 비디오 뷰 크기 (setVideoViewSize)

    @Test func 비디오_뷰_크기가_업데이트됨() {
        let store = makeSUT()
        let size = CGSize(width: 300, height: 400)

        store.send(.setVideoViewSize(size))

        #expect(store.state.videoViewSize == size)
    }

    // MARK: - reduce 테스트 (외부 콜백으로 발생하는 Result)

    @Test func 비디오_프레임이_디코딩되면_샘플버퍼와_각도가_저장됨() {
        let store = makeSUT()
        let rotationAngle: Int16 = 90

        store.reduce(.videoFrameDecoded(
            try! CMSampleBuffer(dataBuffer: nil, formatDescription: nil, numSamples: 0, sampleTimings: [], sampleSizes: []),
            rotationAngle
        ))

        #expect(store.state.rotationAngle == 90)
    }

    @Test func 오버레이_페이즈가_변경되면_기존_페이즈가_교체됨() {
        let store = makeSUT(isTimerMode: true)

        store.reduce(.phaseChanged(.countdown))

        #expect(store.state.overlayPhase == [.countdown])
    }

    @Test func 오버레이_페이즈가_추가되면_기존_페이즈에_더해짐() {
        let store = makeSUT(isTimerMode: true)

        store.reduce(.phaseAppended(.poseSuggestion))

        #expect(store.state.overlayPhase == [.guide, .poseSuggestion])
    }

    @Test func 오버레이_페이즈가_제거되면_해당_페이즈만_사라짐() {
        let store = makeSUT(isTimerMode: true)
        store.reduce(.phaseAppended(.poseSuggestion))

        store.reduce(.phaseRemoved(.guide))

        #expect(store.state.overlayPhase == [.poseSuggestion])
    }
}
