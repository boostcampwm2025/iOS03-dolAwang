//
//  WatchStoreTests.swift
//  WatchStoreTests
//
//  Created by 이상유 on 2026-02-02.
//

import Testing
@testable import mirroringBoothWatch

@MainActor
struct WatchStoreTests {

    // MARK: - Helper

    private func makeSUT() -> WatchConnectionStore {
        WatchConnectionStore(connectionManager: WatchConnectionManager())
    }

    // MARK: - 연결 시작 (startConnecting)

    @Test func 연결_시작해도_상태는_미연결_유지() {
        let store = makeSUT()

        store.send(.startConnecting)

        #expect(store.state.connectionState == .notConnected)
    }

    // MARK: - 연결 해제 (disconnect)

    @Test func 연결_해제하면_미연결_상태로_변경됨() {
        let store = makeSUT()
        store.reduce(.setConnectionState(.connected))

        store.send(.disconnect)

        #expect(store.state.connectionState == .notConnected)
    }

    @Test func 촬영_완료_후_연결_해제하면_미연결_상태로_변경됨() {
        let store = makeSUT()
        store.reduce(.setConnectionState(.connected))
        store.reduce(.setIsReadyToCapture(true))
        store.reduce(.setIsCaptureCompleted(true))

        store.send(.disconnect)

        #expect(store.state.connectionState == .notConnected)
    }

    // MARK: - 촬영 요청 (tapRequestCapture)

    @Test func 촬영_요청해도_상태_변경_없음() {
        let store = makeSUT()
        store.reduce(.setConnectionState(.connected))
        store.reduce(.setIsReadyToCapture(true))

        store.send(.tapRequestCapture)

        #expect(store.state.isCaptureCompleted == false)
    }

    // MARK: - reduce 테스트 (콜백으로 발생하는 Result)

    @Test func 연결_완료_콜백_수신_시_연결_상태가_됨() {
        let store = makeSUT()

        store.reduce(.setConnectionState(.connected))

        #expect(store.state.connectionState == .connected)
    }

    @Test func 촬영_준비_콜백_수신_시_촬영_가능_상태가_됨() {
        let store = makeSUT()

        store.reduce(.setIsReadyToCapture(true))

        #expect(store.state.isReadyToCapture == true)
    }

    @Test func 촬영_완료_콜백_수신_시_촬영_완료_상태가_됨() {
        let store = makeSUT()

        store.reduce(.setIsCaptureCompleted(true))

        #expect(store.state.isCaptureCompleted == true)
    }

    @Test func 연결_끊김_콜백_수신_시_미연결_상태가_됨() {
        let store = makeSUT()
        store.reduce(.setConnectionState(.connected))

        store.reduce(.setConnectionState(.notConnected))

        #expect(store.state.connectionState == .notConnected)
    }

    // MARK: - 대기 애니메이션 (setIsWaiting)

    @Test func 대기_화면이_나타나면_대기_상태가_켜짐() {
        let store = makeSUT()

        store.send(.setIsWaiting(true))

        #expect(store.state.isWaiting == true)
    }

    // MARK: - View 흐름 시나리오

    @Test func 연결부터_촬영_준비까지_전체_흐름() {
        let store = makeSUT()

        // 1. 화면 진입 시 연결 시작
        store.send(.startConnecting)
        #expect(store.state.connectionState == .notConnected)

        // 2. iPhone에서 연결 완료 메시지 수신
        store.reduce(.setConnectionState(.connected))
        #expect(store.state.connectionState == .connected)
        #expect(store.state.isReadyToCapture == false)

        // 3. iPhone에서 촬영 준비 요청 수신
        store.reduce(.setIsReadyToCapture(true))
        #expect(store.state.isReadyToCapture == true)
        #expect(store.state.isCaptureCompleted == false)
    }

    @Test func 촬영_완료_후_종료_흐름() {
        let store = makeSUT()
        store.reduce(.setConnectionState(.connected))
        store.reduce(.setIsReadyToCapture(true))

        // 1. 촬영 완료 콜백 수신
        store.reduce(.setIsCaptureCompleted(true))
        #expect(store.state.isCaptureCompleted == true)

        // 2. 완료 화면에서 닫기 → disconnect
        store.send(.disconnect)
        #expect(store.state.connectionState == .notConnected)
    }
}
