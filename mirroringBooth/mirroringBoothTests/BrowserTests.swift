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

struct BrowserTests {

    // MARK: - 기기 검색 (Discovery) 테스트

    @Test func 주변_기기를_발견하면_deviceFound_이벤트가_발생한다() async {
        // GIVEN
        let browser = Browser()
        let testPeerID = MCPeerID(displayName: "TestPeer")
        let discoveryInfo = ["deviceType": "iPad"]

        // Event 수신 Task 준비
        let expectation = Expectation<BrowsingEvents?>()
        let eventTask = Task {
            for await event in browser.browsingEventStream {
                expectation.fulfill(with: event)
                break
            }
        }
        defer { eventTask.cancel() }

        // 구독 준비 시간
        try? await Task.sleep(nanoseconds: 50_000_000)

        // WHEN
        browser.browser(
            MCNearbyServiceBrowser(peer: testPeerID, serviceType: "mirroringbooth"),
            foundPeer: testPeerID,
            withDiscoveryInfo: discoveryInfo
        )

        // THEN
        let result = await expectation.value
        guard case .deviceFound(let device) = result else {
            Issue.record("Expected .deviceFound event")
            return
        }
        #expect(device.id == "TestPeer")
        #expect(device.type == .iPad)
    }

    @Test func 주변_기기가_사라지면_deviceLost_이벤트가_발생한다() async {
        // GIVEN
        let browser = Browser()
        let testPeerID = MCPeerID(displayName: "TestPeer")
        let discoveryInfo = ["deviceType": "iPad"]

        // 먼저 기기 발견
        browser.browser(
            MCNearbyServiceBrowser(peer: testPeerID, serviceType: "mirroringbooth"),
            foundPeer: testPeerID,
            withDiscoveryInfo: discoveryInfo
        )

        // 스트림 clean up
        _ = Task {
            for await _ in browser.browsingEventStream { break }
        }
        try? await Task.sleep(nanoseconds: 50_000_000)

        // Event 수신 Task 준비
        let expectation = Expectation<BrowsingEvents?>()
        let eventTask = Task {
            for await event in browser.browsingEventStream {
                expectation.fulfill(with: event)
                break
            }
        }
        defer { eventTask.cancel() }
        try? await Task.sleep(nanoseconds: 50_000_000)

        // WHEN
        browser.browser(
            MCNearbyServiceBrowser(peer: testPeerID, serviceType: "mirroringbooth"),
            lostPeer: testPeerID
        )

        // THEN
        let result = await expectation.value
        guard case .deviceLost(let device) = result else {
            Issue.record("Expected .deviceLost event")
            return
        }
        #expect(device.id == "TestPeer")
    }
}

// MARK: - Helper

/// 비동기 이벤트 대기 헬퍼
actor Expectation<T> {
    private var _value: T?
    private var continuation: CheckedContinuation<T, Never>?

    var value: T {
        get async {
            if let existing = _value {
                return existing
            }
            return await withCheckedContinuation { cont in
                continuation = cont
            }
        }
    }

    func fulfill(with value: T) {
        _value = value
        continuation?.resume(returning: value)
        continuation = nil
    }
}
