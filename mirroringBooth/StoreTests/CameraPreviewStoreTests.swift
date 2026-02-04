//
//  CameraPreviewStoreTests.swift
//  StoreTests
//
//  Created by 이상유 on 2026-02-02.
//

import AVFoundation
import Testing
import SwiftUI
@testable import mirroringBooth

final class MockCameraManager: CameraManageable {
    var rawData: ((CMSampleBuffer) -> Void)?
    var onEncodedData: ((Data) -> Void)?
    var onTransferCompleted: (() -> Void)?
    var onAllPhotosStored: (() -> Void)?

    private(set) var startSessionCallCount = 0
    private(set) var stopSessionCallCount = 0
    private(set) var capturePhotoOrientations: [CameraOrientation] = []

    func startSession() {
        startSessionCallCount += 1
    }

    func stopSession() {
        stopSessionCallCount += 1
    }

    func capturePhoto(_ orientation: CameraOrientation) {
        capturePhotoOrientations.append(orientation)
    }

    func sendAllPhotos(using browser: Browser) {}
}

@MainActor
struct CameraPreviewStoreTests {

    // MARK: - Helper

    private func makeSUT(
        deviceName: String = "TestDevice"
    ) -> (store: CameraPreviewStore, manager: MockCameraManager) {
        let manager = MockCameraManager()
        let store = CameraPreviewStore(
            browser: Browser(),
            manager: manager,
            deviceName: deviceName
        )
        return (store, manager)
    }

    // MARK: - 카메라 프리뷰 진입 (entry)

    @Test func 프리뷰에_진입하면_애니메이션이_시작됨() {
        let (store, _) = makeSUT()

        store.send(.entry(withAngle: 1))

        #expect(store.state.animationFlag == true)
    }

    @Test func 프리뷰에_진입하면_다크모드로_설정됨() {
        let (store, _) = makeSUT()

        store.send(.entry(withAngle: 1))

        #expect(store.state.colorScheme == .dark)
    }

    @Test func 프리뷰에_진입하면_촬영완료_상태가_초기화됨() {
        let (store, _) = makeSUT()
        store.reduce(.captureCompleted)

        store.send(.entry(withAngle: 1))

        #expect(store.state.isCaptureCompleted == false)
    }

    @Test func 프리뷰에_진입하면_카메라_세션이_시작됨() {
        let (store, manager) = makeSUT()

        store.send(.entry(withAngle: 1))

        #expect(manager.startSessionCallCount == 1)
    }

    @Test func 프리뷰에_진입하면_초기_각도가_반영됨() {
        let (store, _) = makeSUT()

        store.send(.entry(withAngle: 3))

        #expect(store.state.angle == 90)
    }

    // MARK: - 카메라 프리뷰 퇴장 (exit)

    @Test func 프리뷰를_나가면_카메라_세션이_종료됨() {
        let (store, manager) = makeSUT()

        store.send(.exit)

        #expect(manager.stopSessionCallCount == 1)
    }

    @Test func 프리뷰를_나가면_컬러스킴이_초기화됨() {
        let (store, _) = makeSUT()
        store.send(.entry(withAngle: 1))

        store.send(.exit)

        #expect(store.state.colorScheme == nil)
    }

    // MARK: - 기기 회전

    @Test func 세로_방향이면_각도가_0도() {
        let (store, _) = makeSUT()

        store.send(.updateAngle(rawValue: 1))

        #expect(store.state.angle == 0)
    }

    @Test func landscapeLeft이면_각도가_90도() {
        let (store, _) = makeSUT()

        store.send(.updateAngle(rawValue: 3))

        #expect(store.state.angle == 90)
    }

    @Test func landscapeRight이면_각도가_마이너스90도() {
        let (store, _) = makeSUT()

        store.send(.updateAngle(rawValue: 4))

        #expect(store.state.angle == -90)
    }

    @Test func flat이면_기존_각도가_유지됨() {
        let (store, _) = makeSUT()
        store.send(.updateAngle(rawValue: 3)) // 90도

        store.send(.updateAngle(rawValue: 5)) // flat

        #expect(store.state.angle == 90)
    }

    // MARK: - 미러링 연결 해제

    @Test func 미러링_연결이_끊기면_상태가_반영됨() {
        let (store, _) = makeSUT()

        store.send(.isMirroringDisconnected)

        #expect(store.state.isMirroringDisconnected == true)
    }

    // MARK: - reduce 테스트 (Browser 관련 Intent 대체)

    @Test func 촬영이_완료되면_완료_플래그가_설정됨() {
        let (store, _) = makeSUT()

        store.reduce(.captureCompleted)

        #expect(store.state.isCaptureCompleted == true)
    }

    @Test func 전송_카운트가_업데이트됨() {
        let (store, _) = makeSUT()

        store.reduce(.setTransferCount(3))

        #expect(store.state.transfercount == 3)
    }

    @Test func 전송중_상태가_반영됨() {
        let (store, _) = makeSUT()

        store.reduce(.setIsTransferring(true))

        #expect(store.state.isTransferring == true)
    }
}
