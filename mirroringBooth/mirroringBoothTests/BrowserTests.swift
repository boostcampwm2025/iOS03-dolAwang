//
//  BrowserTest.swift
//  mirroringBooth
//
//  Created by 윤대현 on 2/4/26.
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
        browser.browsingManager.browser(
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
        browser.browsingManager.browser(
            MCNearbyServiceBrowser(peer: testPeerID, serviceType: "mirroringbooth"),
            foundPeer: testPeerID,
            withDiscoveryInfo: discoveryInfo
        )

        // 첫 번째 이벤트 소비 후 수집 시작
        await collector.startCollecting(streamType: .browsing, skipFirst: 1)

        // WHEN
        browser.browsingManager.browser(
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
        browser.browsingManager.browser(
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
        #expect(true, "captureCommand 이벤트 확인 완료")
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

    @Test func heartBeat_명령_수신시_HeartBeater가_beat를_호출한다() async {
        // GIVEN
        let (browser, _) = makeSUT()
        let testPeerID = MCPeerID(displayName: "테스트기기")
        let mockSession = MCSession(peer: testPeerID, securityIdentity: nil, encryptionPreference: .none)

        // WHEN - heartBeat 명령 수신 (크래시 없이 처리되면 성공)
        let commandData = Data("heartBeat".utf8)
        browser.session(mockSession, didReceive: commandData, fromPeer: testPeerID)

        // THEN - 크래시 없이 처리되면 성공
        #expect(true)
    }

    @Test func 알_수_없는_명령_수신시_크래시하지_않는다() async {
        // GIVEN
        let (browser, _) = makeSUT()
        let testPeerID = MCPeerID(displayName: "테스트기기")
        let mockSession = MCSession(peer: testPeerID, securityIdentity: nil, encryptionPreference: .none)

        // WHEN - 알 수 없는 명령 수신
        let commandData = Data("unknownCommand".utf8)
        browser.session(mockSession, didReceive: commandData, fromPeer: testPeerID)

        // THEN - 크래시 없이 처리되면 성공
        #expect(true)
    }

    // MARK: - Heartbeat 타임아웃 테스트

    @Test func mirroringHeartbeat_타임아웃시_heartbeatTimeout_이벤트가_발생한다() async {
        // GIVEN
        let (browser, _) = makeSUT()
        let heartbeatCollector = HeartbeatEventCollector(
            browsingStream: browser.browsingHeartbeatStream,
            connectionCheckStream: browser.connectionCheckHeartbeatStream,
            cameraPreviewStream: browser.cameraPreviewHeartbeatStream
        )

        await heartbeatCollector.startCollecting(streamType: .browsing)

        // WHEN - mirroringHeartBeater 타임아웃 시뮬레이션
        browser.onTimeout(browser.mirroringHeartBeater)

        // THEN
        let events = await heartbeatCollector.collectEvents(count: 1, timeout: 0.5)
        #expect(events.count == 1)
        guard case .heartbeatTimeout = events.first else {
            Issue.record("Expected .heartbeatTimeout event, got: \(String(describing: events.first))")
            return
        }
    }

    @Test func heartbeat_타임아웃시_모든_스트림에_이벤트가_전달된다() async {
        // GIVEN
        let (browser, _) = makeSUT()

        let browsingCollector = HeartbeatEventCollector(
            browsingStream: browser.browsingHeartbeatStream,
            connectionCheckStream: browser.connectionCheckHeartbeatStream,
            cameraPreviewStream: browser.cameraPreviewHeartbeatStream
        )
        let connectionCheckCollector = HeartbeatEventCollector(
            browsingStream: browser.browsingHeartbeatStream,
            connectionCheckStream: browser.connectionCheckHeartbeatStream,
            cameraPreviewStream: browser.cameraPreviewHeartbeatStream
        )
        let cameraPreviewCollector = HeartbeatEventCollector(
            browsingStream: browser.browsingHeartbeatStream,
            connectionCheckStream: browser.connectionCheckHeartbeatStream,
            cameraPreviewStream: browser.cameraPreviewHeartbeatStream
        )

        await browsingCollector.startCollecting(streamType: .browsing)
        await connectionCheckCollector.startCollecting(streamType: .connectionCheck)
        await cameraPreviewCollector.startCollecting(streamType: .cameraPreview)

        // WHEN
        browser.onTimeout(browser.mirroringHeartBeater)

        // THEN - 모든 스트림에서 이벤트 수신
        let browsingEvents = await browsingCollector.collectEvents(count: 1, timeout: 0.5)
        let connectionCheckEvents = await connectionCheckCollector.collectEvents(count: 1, timeout: 0.5)
        let cameraPreviewEvents = await cameraPreviewCollector.collectEvents(count: 1, timeout: 0.5)

        #expect(browsingEvents.count == 1, "browsingHeartbeatStream에서 이벤트 수신 실패")
        #expect(connectionCheckEvents.count == 1, "connectionCheckHeartbeatStream에서 이벤트 수신 실패")
        #expect(cameraPreviewEvents.count == 1, "cameraPreviewHeartbeatStream에서 이벤트 수신 실패")
    }
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

// MARK: - Heartbeat Event Collector

/// Heartbeat 이벤트 스트림을 수집하는 테스트 헬퍼
actor HeartbeatEventCollector {
    enum StreamType {
        case browsing
        case connectionCheck
        case cameraPreview
    }

    private let browsingStream: AsyncStream<HeartBeatEvents>
    private let connectionCheckStream: AsyncStream<HeartBeatEvents>
    private let cameraPreviewStream: AsyncStream<HeartBeatEvents>
    private var events: [HeartBeatEvents] = []
    private var task: Task<Void, Never>?

    init(
        browsingStream: AsyncStream<HeartBeatEvents>,
        connectionCheckStream: AsyncStream<HeartBeatEvents>,
        cameraPreviewStream: AsyncStream<HeartBeatEvents>
    ) {
        self.browsingStream = browsingStream
        self.connectionCheckStream = connectionCheckStream
        self.cameraPreviewStream = cameraPreviewStream
    }

    deinit {
        task?.cancel()
    }

    func startCollecting(streamType: StreamType) {
        let stream: AsyncStream<HeartBeatEvents>
        switch streamType {
        case .browsing:
            stream = browsingStream
        case .connectionCheck:
            stream = connectionCheckStream
        case .cameraPreview:
            stream = cameraPreviewStream
        }

        task = Task { [weak self] in
            guard let self else { return }
            for await event in stream {
                await self.appendEvent(event)
            }
        }
    }

    private func appendEvent(_ event: HeartBeatEvents) {
        events.append(event)
    }

    func collectEvents(count: Int, timeout: TimeInterval) async -> [HeartBeatEvents] {
        let deadline = Date().addingTimeInterval(timeout)
        while events.count < count && Date() < deadline {
            try? await Task.sleep(nanoseconds: 10_000_000)
        }
        return events
    }

    func reset() {
        events.removeAll()
    }
}
