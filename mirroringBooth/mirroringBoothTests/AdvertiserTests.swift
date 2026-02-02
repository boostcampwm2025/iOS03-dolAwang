//
//  AdvertiserTests.swift
//  mirroringBooth
//
//  Created by Liam on 2/2/26.
//

import XCTest
import MultipeerConnectivity
@testable import mirroringBooth

// AI 보조로 작성
final class AdvertiserTests: XCTestCase {
    var advertiser: Advertiser!
    var mockCacheManager: PhotoCacheManager!

    override func setUp() async throws {
        mockCacheManager = PhotoCacheManager.shared
        await mockCacheManager.startNewSession()
        advertiser = await Advertiser(photoCacheManager: mockCacheManager)
    }

    override func tearDown() async throws {
        await advertiser.disconnect()
        advertiser = nil
        await mockCacheManager.clearCache()
        mockCacheManager = nil
    }

    func testVideoStreamYieldsDataWhenReceived() async throws {
        // GIVEN: Session이 설정되고 스트림 구독이 준비됨
        let testData = "testData".data(using: .utf8)!
        let peerID = MCPeerID(displayName: "TestPeer")
        let session = try await setupStreamingSession(with: peerID)

        var receivedData: Data?
        let streamTask = Task {
            for await event in await advertiser.videoStream {
                if case .streamDataReceived(let data) = event {
                    receivedData = data
                    break
                }
            }
        }
        defer { streamTask.cancel() }

        // 구독 준비 시간
        try await Task.sleep(nanoseconds: 50_000_000)

        // WHEN: 데이터를 수신함
        await advertiser.session(session, didReceive: testData, fromPeer: peerID)

        // THEN: videoStream을 통해 해당 데이터가 전달됨
        try await Task.sleep(nanoseconds: 100_000_000)
        XCTAssertEqual(receivedData, testData, "Received data should match sent data")
    }

    // Helper method
    private func setupStreamingSession(with peerID: MCPeerID) async throws -> MCSession {
        let context = Browser.SessionType.streaming.rawValue.data(using: .utf8)
        let dummyAdvertiser = MCNearbyServiceAdvertiser(
            peer: peerID,
            discoveryInfo: nil,
            serviceType: "test"
        )

        var capturedSession: MCSession?

        await advertiser.advertiser(
            dummyAdvertiser,
            didReceiveInvitationFromPeer: peerID,
            withContext: context
        ) { accept, session in
            XCTAssertTrue(accept, "Should accept streaming invitation")
            capturedSession = session
        }

        guard let session = capturedSession else {
            throw TestError.sessionNotCreated
        }

        return session
    }

    enum TestError: Error {
        case sessionNotCreated
    }
}
