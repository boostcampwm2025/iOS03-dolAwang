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
/// AI를 활용해 작성했습니다.
@MainActor
struct BrowserTests {
    
    private func makeSUT() -> (browser: Browser, eventCollector: EventCollector) {
        let browser = Browser()
        let collector = EventCollector(
            browsingStream: browser.browsingEventStream,
            cameraStream: browser.cameraStreamEventStream
        )
        return (browser, collector)
    }

    // MARK: - 기기 검색

    @Test func 주변_기기를_발견하면_deviceFound_이벤트가_발생한다() async {
        // GIVEN
        let (browser, collector) = makeSUT()
        let testPeerID = MCPeerID(displayName: "몽이")
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
        #expect(device.id == "몽이")
        #expect(device.type == .iPad)
    }

    @Test func 주변_기기가_사라지면_deviceLost_이벤트가_발생한다() async {
        // GIVEN
        let (browser, collector) = makeSUT()
        let testPeerID = MCPeerID(displayName: "몽이")
        let discoveryInfo = ["deviceType": "iPad"]

        // 기기 발견 시뮬레이션
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
        #expect(device.id == "몽이")
    }

    @Test func deviceType이_없는_기기는_발견_이벤트가_발생하지_않는다() async {
        // GIVEN
        let (browser, collector) = makeSUT()
        let testPeerID = MCPeerID(displayName: "몽이")
        let emptyDiscoveryInfo: [String: String] = [:]  // deviceType 없는 상태

        await collector.startCollecting(streamType: .browsing)

        // WHEN
        browser.browser(
            MCNearbyServiceBrowser(peer: testPeerID, serviceType: "mirroringbooth"),
            foundPeer: testPeerID,
            withDiscoveryInfo: emptyDiscoveryInfo
        )

        // THEN
        let events = await collector.collectBrowsingEvents(count: 1, timeout: 0.3)
        #expect(events.isEmpty, "deviceType 없이 발견된 기기는 이벤트가 발생하지 않아야 합니다.")
    }

    // MARK: - 카메라 스트림 이벤트 테스트

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

    // MARK: - 명령 전송

    @Test func 세션이_없을때_sendCommand는_실패해도_크래시하지_않는다() async {
        // GIVEN
        let (browser, _) = makeSUT()

        // WHEN - mirroringCommandSession이 nil인 상태
        browser.sendCommand(.heartBeat)

        // THEN - 크래시하지 않으면 성공
        #expect(true)
    }

    @Test func 세션이_없을때_sendRemoteCommand는_실패해도_크래시하지_않는다() async {
        // GIVEN
        let (browser, _) = makeSUT()

        // WHEN - remoteSession이 nil인 상태
        browser.sendRemoteCommand(.heartBeat)

        // THEN - 크래시하지 않으면 성공
        #expect(true)
    }

    @Test func 세션이_없을때_sendStreamData는_실패해도_크래시하지_않는다() async {
        // GIVEN
        let (browser, _) = makeSUT()
        let testData = Data([0x01, 0x02, 0x03])

        // WHEN - mirroringSession이 nil인 상태
        browser.sendStreamData(testData)

        // THEN - 크래시하지 않으면 성공
        #expect(true)
    }

    // MARK: - 검색 시작/중지 및 연결 해제

    @Test func startSearching_호출시_크래시하지_않는다() async {
        // GIVEN
        let (browser, _) = makeSUT()

        // WHEN
        browser.startSearching()

        // THEN
        #expect(true)

        // Cleanup
        browser.stopSearching()
    }

    @Test func disconnect_호출시_크래시하지_않는다() async {
        // GIVEN
        let (browser, _) = makeSUT()

        // WHEN
        browser.disconnect()

        // THEN
        #expect(true)
    }

    // MARK: - TODO

    // executeCommand는 현재 private이므로 리팩터링 후
    // BrowserCommandManager를 통해 명령 수신 테스트 진행 예정입니다.

    // MCSession 의존성 주입이 필요하므로 리팩터링 후
    // 연결 상태 변경(deviceConnected, deviceConnectionFailed) 테스트 진행 예정입니다.

    // sendPhotoResource 완료 이벤트(.sendPhoto)는
    // 실제 MCSession.sendResource 콜백이 필요하므로 리팩터링 후 테스트 진행 예정입니다.
}

// MARK: - Event Collector (Test Helper)

/// 비동기 이벤트 스트림을 수집하는 테스트 헬퍼
/// 실제 스트림을 소비하고 이벤트를 배열로 수집합니다.
actor EventCollector {
    enum StreamType {
        case browsing
        case cameraStream
    }

    private let browsingStream: AsyncStream<BrowsingEvents>
    private let cameraStream: AsyncStream<CameraStreamEvents>
    private var browsingEvents: [BrowsingEvents] = []
    private var cameraStreamEvents: [CameraStreamEvents] = []
    private var browsingTask: Task<Void, Never>?
    private var cameraStreamTask: Task<Void, Never>?

    init(
        browsingStream: AsyncStream<BrowsingEvents>,
        cameraStream: AsyncStream<CameraStreamEvents>
    ) {
        self.browsingStream = browsingStream
        self.cameraStream = cameraStream
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
                for await event in browsingStream {
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
                for await event in cameraStream {
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
            try? await Task.sleep(nanoseconds: 10_000_000)
        }
        return browsingEvents
    }

    /// CameraStream 이벤트 수집 (타임아웃 지원)
    func collectCameraStreamEvents(count: Int, timeout: TimeInterval) async -> [CameraStreamEvents] {
        let deadline = Date().addingTimeInterval(timeout)
        while cameraStreamEvents.count < count && Date() < deadline {
            try? await Task.sleep(nanoseconds: 10_000_000)
        }
        return cameraStreamEvents
    }

    /// 수집된 이벤트 초기화
    func reset() {
        browsingEvents.removeAll()
        cameraStreamEvents.removeAll()
    }
}
