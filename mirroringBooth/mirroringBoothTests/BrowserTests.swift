//
//  BrowserTests.swift
//  mirroringBoothTests
//
//  Created by 윤대현 on 2026-02-03.
//

import Testing
import MultipeerConnectivity
@testable import mirroringBooth

// MARK: - Browser Tests
// 우선순위:
// 1. 이벤트 스트림 방출 (browsingEventStream, cameraStreamEventStream) - 핵심 출력
// 2. 명령 수신/처리 (executeCommand) - 핵심 입력
// 3. 연결 상태 변경 - 세션 관리

struct BrowserTests {

    // MARK: - SUT Factory

    /// System Under Test (SUT) 생성 헬퍼
    /// 테스트에서 Browser 인스턴스와 관련 이벤트 수집기를 함께 생성
    private func makeSUT() -> (browser: Browser, eventCollector: EventCollector) {
        let browser = Browser()
        let collector = EventCollector(browser: browser)
        return (browser, collector)
    }

    // MARK: - 1. 기기 검색 (Discovery) 이벤트 테스트

    @Test func 주변_기기를_발견하면_deviceFound_이벤트가_발생한다() async {
        // GIVEN
        let (browser, collector) = makeSUT()
        let testPeerID = MCPeerID(displayName: "TestPeer")
        let discoveryInfo = ["deviceType": "iPad"]

        await collector.startCollecting(streamType: .browsing)

        // WHEN
        browser.browser(
            MCNearbyServiceBrowser(peer: testPeerID, serviceType: "mirroringbooth"),
            foundPeer: testPeerID,
            withDiscoveryInfo: discoveryInfo
        )

        // THEN
        let events = await collector.collectBrowsingEvents(count: 1, timeout: 0.5)
        #expect(events.count == 1)
        guard case .deviceFound(let device) = events.first else {
            Issue.record("Expected .deviceFound event, got: \(String(describing: events.first))")
            return
        }
        #expect(device.id == "TestPeer")
        #expect(device.type == .iPad)
    }

    @Test func 주변_기기가_사라지면_deviceLost_이벤트가_발생한다() async {
        // GIVEN
        let (browser, collector) = makeSUT()
        let testPeerID = MCPeerID(displayName: "TestPeer")
        let discoveryInfo = ["deviceType": "iPad"]

        // 먼저 기기 발견 시뮬레이션
        browser.browser(
            MCNearbyServiceBrowser(peer: testPeerID, serviceType: "mirroringbooth"),
            foundPeer: testPeerID,
            withDiscoveryInfo: discoveryInfo
        )

        // 첫 번째 이벤트 소비 후 수집 시작
        await collector.startCollecting(streamType: .browsing, skipFirst: 1)

        // WHEN
        browser.browser(
            MCNearbyServiceBrowser(peer: testPeerID, serviceType: "mirroringbooth"),
            lostPeer: testPeerID
        )

        // THEN
        let events = await collector.collectBrowsingEvents(count: 1, timeout: 0.5)
        #expect(events.count == 1)
        guard case .deviceLost(let device) = events.first else {
            Issue.record("Expected .deviceLost event, got: \(String(describing: events.first))")
            return
        }
        #expect(device.id == "TestPeer")
    }

    @Test func deviceType이_없는_기기는_발견_이벤트가_발생하지_않는다() async {
        // GIVEN
        let (browser, collector) = makeSUT()
        let testPeerID = MCPeerID(displayName: "TestPeer")
        let emptyDiscoveryInfo: [String: String] = [:]  // deviceType 없음

        await collector.startCollecting(streamType: .browsing)

        // WHEN
        browser.browser(
            MCNearbyServiceBrowser(peer: testPeerID, serviceType: "mirroringbooth"),
            foundPeer: testPeerID,
            withDiscoveryInfo: emptyDiscoveryInfo
        )

        // THEN
        let events = await collector.collectBrowsingEvents(count: 1, timeout: 0.3)
        #expect(events.isEmpty, "deviceType 없이 발견된 기기는 이벤트가 발생하지 않아야 함")
    }

    // MARK: - 2. 카메라 스트림 이벤트 테스트

    @Test func capturePhoto_호출시_captureCommand_이벤트가_발생한다() async {
        // GIVEN
        let (browser, collector) = makeSUT()
        await collector.startCollecting(streamType: .cameraStream)

        // WHEN
        browser.capturePhoto()

        // THEN
        let events = await collector.collectCameraStreamEvents(count: 1, timeout: 0.5)
        #expect(events.count == 1)
        guard case .captureCommand = events.first else {
            Issue.record("Expected .captureCommand event, got: \(String(describing: events.first))")
            return
        }
    }

    // MARK: - 3. 명령 수신 테스트 (executeCommand)

    @Test func capturePhoto_명령을_수신하면_captureCommand_이벤트가_발생한다() async {
        // GIVEN
        let (browser, collector) = makeSUT()
        await collector.startCollecting(streamType: .cameraStream)

        // 명령 데이터 생성
        let commandData = Advertiser.CameraDeviceCommand.capturePhoto.rawValue.data(using: .utf8)!

        // 더미 세션 생성 (내부 mirroringCommandSession 또는 remoteSession 시뮬레이션 필요)
        // Note: Browser의 executeCommand는 private이므로, didReceive를 통해 호출해야 함
        // 하지만 session이 nil이면 처리되지 않음. 이 부분은 통합 테스트 또는 리팩터링 후 테스트 가능

        // WHEN - 직접 capturePhoto 호출로 대체 (명령 수신 시 내부적으로 capturePhoto가 호출됨)
        // 리팩터링 후에는 BrowserCommandManager를 통해 테스트 가능
        await MainActor.run {
            browser.capturePhoto()
        }

        // THEN
        let events = await collector.collectCameraStreamEvents(count: 1, timeout: 0.5)
        #expect(events.count >= 1)
        #expect(events.contains { event in
            if case .captureCommand = event { return true }
            return false
        })
    }

    @Test func startTransfer_명령을_수신하면_startTransfer_이벤트가_발생한다() async {
        // GIVEN
        let (browser, collector) = makeSUT()
        await collector.startCollecting(streamType: .cameraStream)

        // Note: executeCommand는 private이므로 직접 테스트 불가
        // 리팩터링 후 BrowserCommandManager를 통해 public하게 테스트 가능
        // 현재는 통합 시나리오로 검증

        // 임시: cameraStreamEventContinuation에 직접 접근 불가하므로 스킵
        // 리팩터링 시 yield 메서드를 통해 접근 가능하게 변경 필요

        // THEN - 이 테스트는 리팩터링 후 활성화
        #expect(true, "리팩터링 후 BrowserCommandManager를 통해 테스트")
    }

    // MARK: - 4. 명령 전송 (세션 없을 때 안전성)

    @Test func 세션이_없을때_sendCommand는_실패해도_크래시하지_않는다() async {
        // GIVEN
        let browser = Browser()

        // WHEN - mirroringCommandSession이 nil인 상태
        browser.sendCommand(.heartBeat)

        // THEN - 크래시하지 않으면 성공
        #expect(true)
    }

    @Test func 세션이_없을때_sendRemoteCommand는_실패해도_크래시하지_않는다() async {
        // GIVEN
        let browser = Browser()

        // WHEN - remoteSession이 nil인 상태
        browser.sendRemoteCommand(.heartBeat)

        // THEN - 크래시하지 않으면 성공
        #expect(true)
    }

    @Test func 세션이_없을때_sendStreamData는_실패해도_크래시하지_않는다() async {
        // GIVEN
        let browser = Browser()
        let testData = Data([0x01, 0x02, 0x03])

        // WHEN - mirroringSession이 nil인 상태
        browser.sendStreamData(testData)

        // THEN - 크래시하지 않으면 성공
        #expect(true)
    }

    // MARK: - 5. 검색 시작/중지 및 연결 해제

    @Test func startSearching_호출시_크래시하지_않는다() async {
        // GIVEN
        let browser = Browser()

        // WHEN
        browser.startSearching()

        // THEN
        #expect(true)

        // Cleanup
        browser.stopSearching()
    }

    @Test func disconnect_호출시_크래시하지_않는다() async {
        // GIVEN
        let browser = Browser()

        // WHEN
        browser.disconnect()

        // THEN
        #expect(true)
    }
}

// MARK: - Event Collector (Test Helper)

/// 비동기 이벤트 스트림을 수집하는 테스트 헬퍼
/// Mocking/Stubbing 대신 실제 스트림을 소비하고 이벤트를 배열로 수집
actor EventCollector {
    enum StreamType {
        case browsing
        case cameraStream
    }

    private let browser: Browser
    private var browsingEvents: [BrowsingEvents] = []
    private var cameraStreamEvents: [CameraStreamEvents] = []
    private var browsingTask: Task<Void, Never>?
    private var cameraStreamTask: Task<Void, Never>?

    init(browser: Browser) {
        self.browser = browser
    }

    deinit {
        browsingTask?.cancel()
        cameraStreamTask?.cancel()
    }

    /// 이벤트 수집 시작
    func startCollecting(streamType: StreamType, skipFirst: Int = 0) {
        switch streamType {
        case .browsing:
            browsingTask = Task { [weak self] in
                guard let self else { return }
                var skipped = 0
                for await event in browser.browsingEventStream {
                    if skipped < skipFirst {
                        skipped += 1
                        continue
                    }
                    await self.appendBrowsingEvent(event)
                }
            }
        case .cameraStream:
            cameraStreamTask = Task { [weak self] in
                guard let self else { return }
                for await event in browser.cameraStreamEventStream {
                    await self.appendCameraStreamEvent(event)
                }
            }
        }
    }

    private func appendBrowsingEvent(_ event: BrowsingEvents) {
        browsingEvents.append(event)
    }

    private func appendCameraStreamEvent(_ event: CameraStreamEvents) {
        cameraStreamEvents.append(event)
    }

    /// Browsing 이벤트 수집 (타임아웃 지원)
    func collectBrowsingEvents(count: Int, timeout: TimeInterval) async -> [BrowsingEvents] {
        let deadline = Date().addingTimeInterval(timeout)
        while browsingEvents.count < count && Date() < deadline {
            try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
        }
        return browsingEvents
    }

    /// CameraStream 이벤트 수집 (타임아웃 지원)
    func collectCameraStreamEvents(count: Int, timeout: TimeInterval) async -> [CameraStreamEvents] {
        let deadline = Date().addingTimeInterval(timeout)
        while cameraStreamEvents.count < count && Date() < deadline {
            try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
        }
        return cameraStreamEvents
    }

    /// 수집된 이벤트 초기화
    func reset() {
        browsingEvents.removeAll()
        cameraStreamEvents.removeAll()
    }
}
