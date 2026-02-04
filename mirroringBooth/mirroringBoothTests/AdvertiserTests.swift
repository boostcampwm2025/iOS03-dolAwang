//
//  AdvertiserTests.swift
//  mirroringBoothTests
//
//  Created by Liam on 2/2/26.
//

import MultipeerConnectivity
import XCTest
@testable import mirroringBooth

// AI 보조로 작성
final class AdvertiserTests: XCTestCase {
    var advertiser: Advertiser!
    var cacheManager: PhotoCacheManager!

    override func setUp() async throws {
        cacheManager = PhotoCacheManager.shared
        await cacheManager.startNewSession()
        advertiser = await Advertiser(photoCacheManager: cacheManager)
    }

    override func tearDown() async throws {
        await advertiser.disconnect()
        advertiser = nil
        await cacheManager.clearCache()
        cacheManager = nil
    }

    // MARK: - Video Stream Tests

    func test비디오스트림_데이터수신시_정상_전달() async throws {
        // GIVEN
        let testData = "testData".data(using: .utf8)!
        let peerID = MCPeerID(displayName: "TestPeer")
        let session = try setupStreamingSession(with: peerID)

        let expectation = expectation(description: "비디오 데이터 수신 대기")

        let streamTask = Task {
            for await event in await advertiser.videoStream {
                if case .streamDataReceived(let data) = event {
                    if data == testData {
                        expectation.fulfill()
                    }
                }
            }
        }
        defer { streamTask.cancel() }

        // WHEN
        await advertiser.session(session, didReceive: testData, fromPeer: peerID)

        // THEN
        await fulfillment(of: [expectation], timeout: 1.0)
    }

    // MARK: - Advertising Stream Tests

    func test광고스트림_연결성공_이벤트_전달() async throws {
        // GIVEN
        let expectation = expectation(description: "연결 성공 이벤트 대기")
        let peerID = MCPeerID(displayName: "CommandPeer")
        let session = try setupCommandSession(with: peerID)

        let streamTask = Task {
            for await event in await advertiser.advertisingStream {
                if case .onConnected = event {
                    expectation.fulfill()
                }
            }
        }
        defer { streamTask.cancel() }


        // WHEN: 명령 세션이 연결됨
        await advertiser.session(session, peer: peerID, didChange: .connected)

        // THEN
        await fulfillment(of: [expectation], timeout: 1.0)
    }

    func test광고스트림_모드선택_명령_전달() async throws {
        // GIVEN
        let expectationWithRemote = expectation(description: "원격 포함 모드 선택 명령 대기")
        let expectationWithoutRemote = expectation(description: "원격 미포함 모드 선택 명령 대기")

        let peerID = MCPeerID(displayName: "CommandPeer")
        let session = try setupCommandSession(with: peerID)

        let streamTask = Task {
            for await event in await advertiser.advertisingStream {
                switch event {
                case .navigateToSelectModeCommand(let isRemote):
                    if isRemote {
                        expectationWithRemote.fulfill()
                    } else {
                        expectationWithoutRemote.fulfill()
                    }
                default: break
                }
            }
        }
        defer { streamTask.cancel() }


        // WHEN: 원격 포함 명령 수신
        let commandWithRemote = Browser.MirroringDeviceCommand.navigateToSelectModeWithRemote.rawValue.data(using: .utf8)!
        await advertiser.session(session, didReceive: commandWithRemote, fromPeer: peerID)

        // WHEN: 원격 미포함 명령 수신
        let commandWithoutRemote = Browser.MirroringDeviceCommand.navigateToSelectModeWithoutRemote.rawValue.data(using: .utf8)!
        await advertiser.session(session, didReceive: commandWithoutRemote, fromPeer: peerID)

        // THEN
        await fulfillment(of: [expectationWithRemote, expectationWithoutRemote], timeout: 1.0)
    }

    func test광고스트림_리모트연결_명령_전달() async throws {
        // GIVEN
        let expectation = expectation(description: "리모트 연결 명령 대기")
        let peerID = MCPeerID(displayName: "CommandPeer")
        let session = try setupCommandSession(with: peerID)

        let streamTask = Task {
            for await event in await advertiser.advertisingStream {
                if case .navigateToRemoteConnected = event {
                    expectation.fulfill()
                }
            }
        }
        defer { streamTask.cancel() }


        // WHEN
        let command = Browser.RemoteDeviceCommand.navigateToRemoteConnected.rawValue.data(using: .utf8)!
        await advertiser.session(session, didReceive: command, fromPeer: peerID)

        // THEN
        await fulfillment(of: [expectation], timeout: 1.0)
    }

    // MARK: - Mode Selection Stream Tests

    func test모드선택스트림_모드선택뷰_전환_명령_전달() async throws {
        // GIVEN
        let expectation = expectation(description: "모드 선택 뷰 전환 명령 대기")
        let peerID = MCPeerID(displayName: "CommandPeer")
        let session = try setupCommandSession(with: peerID)

        let streamTask = Task {
            for await event in await advertiser.modeSelectionStream {
                if case .switchModeSelectionView = event {
                    expectation.fulfill()
                }
            }
        }
        defer { streamTask.cancel() }


        // WHEN
        let command = Browser.MirroringDeviceCommand.switchSelectModeView.rawValue.data(using: .utf8)!
        await advertiser.session(session, didReceive: command, fromPeer: peerID)

        // THEN
        await fulfillment(of: [expectation], timeout: 1.0)
    }

    // MARK: - Remote Connected View Stream Tests

    func test리모트연결뷰스트림_이벤트_전달() async throws {
        // GIVEN
        let expectationCapture = expectation(description: "리모트 촬영 이동 명령 대기")
        let expectationHome = expectation(description: "홈 화면 이동 명령 대기")

        let peerID = MCPeerID(displayName: "CommandPeer")
        let session = try setupCommandSession(with: peerID)

        let streamTask = Task {
            for await event in await advertiser.remoteConnectedViewStream {
                switch event {
                case .navigateToRemoteCapture:
                    expectationCapture.fulfill()
                case .navigateToHome:
                    expectationHome.fulfill()
                }
            }
        }
        defer { streamTask.cancel() }


        // WHEN: Capture 명령
        let commandCapture = Browser.RemoteDeviceCommand.navigateToRemoteCapture.rawValue.data(using: .utf8)!
        await advertiser.session(session, didReceive: commandCapture, fromPeer: peerID)

        // WHEN: Home 명령
        let commandHome = Browser.RemoteDeviceCommand.navigateToHome.rawValue.data(using: .utf8)!
        await advertiser.session(session, didReceive: commandHome, fromPeer: peerID)

        // THEN
        await fulfillment(of: [expectationCapture, expectationHome], timeout: 1.0)
    }

    // MARK: - Remote Capture View Stream Tests

    func test리모트촬영뷰스트림_리모트완료_명령_전달() async throws {
        // GIVEN
        let expectation = expectation(description: "리모트 완료 명령 대기")
        let peerID = MCPeerID(displayName: "CommandPeer")
        let session = try setupCommandSession(with: peerID)

        let streamTask = Task {
            for await event in await advertiser.remoteCaptureViewStream {
                if case .navigateToRemoteComplete = event {
                    expectation.fulfill()
                }
            }
        }
        defer { streamTask.cancel() }


        // WHEN
        let command = Browser.RemoteDeviceCommand.navigateToRemoteComplete.rawValue.data(using: .utf8)!
        await advertiser.session(session, didReceive: command, fromPeer: peerID)

        // THEN
        await fulfillment(of: [expectation], timeout: 1.0)
    }

    // MARK: - Streaming Store Stream Tests

    func test스트리밍스토어스트림_이벤트_전달() async throws {
        // GIVEN
        let expectationAllStored = expectation(description: "모든 사진 저장 완료 대기")
        let expectationUpdateCount = expectation(description: "촬영 횟수 업데이트 대기")
        let expectationCaptureEffect = expectation(description: "캡처 효과 명령 대기")
        let expectationPhotoReceived = expectation(description: "사진 수신 완료 대기")

        let peerID = MCPeerID(displayName: "CommandPeer")
        let session = try setupCommandSession(with: peerID)

        let streamTask = Task {
            for await event in await advertiser.streamingStoreStream {
                switch event {
                case .onStoreAllPhotos: expectationAllStored.fulfill()
                case .onUpdateCaptureCount: expectationUpdateCount.fulfill()
                case .onCaptureEffect: expectationCaptureEffect.fulfill()
                case .onPhotoReceived: expectationPhotoReceived.fulfill()
                }
            }
        }
        defer { streamTask.cancel() }


        // WHEN
        let commandAllStored = Browser.MirroringDeviceCommand.onStoreAllPhotos.rawValue.data(using: .utf8)!
        await advertiser.session(session, didReceive: commandAllStored, fromPeer: peerID)

        let commandUpdateCount = Browser.MirroringDeviceCommand.onUpdateCaptureCount.rawValue.data(using: .utf8)!
        await advertiser.session(session, didReceive: commandUpdateCount, fromPeer: peerID)

        let commandCaptureEffect = Browser.MirroringDeviceCommand.captureEffect.rawValue.data(using: .utf8)!
        await advertiser.session(session, didReceive: commandCaptureEffect, fromPeer: peerID)

        // 사진 수신 시뮬레이션 (didFinishReceivingResource)
        // 파일이 없으면 에러가 날 수 있으므로 임시 파일 생성
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test_photo.jpg")
        try "dummy data".data(using: .utf8)?.write(to: tempURL)

        // streaming session이 아닌 command session으로 사진이 오진 않겠지만, delegate 메서드 호출 테스트이므로 세션 객체 전달
        await advertiser.session(session, didFinishReceivingResourceWithName: "test", fromPeer: peerID, at: tempURL, withError: nil)

        // THEN
        await fulfillment(of: [expectationAllStored, expectationUpdateCount, expectationCaptureEffect, expectationPhotoReceived], timeout: 2.0)
    }

    // MARK: - Root Stream Tests (Timeout)

    func test루트스트림_하트비트_타임아웃_이벤트_전달() async throws {
        // GIVEN
        let expectation = expectation(description: "하트비트 타임아웃 이벤트 대기")

        // HeartBeaterDelegate.onTimeout을 직접 호출하기 어려우므로,
        // Advertiser가 HeartBeaterDelegate를 채택하고 있으므로 직접 onTimeout을 호출하여 테스트
        // (단, onTimeout이 public이 아니거나 internal이면 테스트 타겟에서 접근 가능해야 함)
        // 여기서는 HeartBeater를 모킹하거나, private 메서드를 호출할 수 없으므로
        // HeartBeaterDelegate의 메서드가 internal이라고 가정하고 호출.
        // 만약 접근 불가하다면, HeartBeater 동작(시간 경과)을 기다려야 하는데 시간이 걸림.
        // 대안: Advertiser+HeartBeater.swift의 onTimeout이 내부적으로 호출하는 로직을 검증해야 함.
        // 이 테스트 파일이 @testable import를 사용하므로 internal 메서드 접근 가능.

        let streamTask = Task {
            for await event in await advertiser.rootStream {
                if case .onHeartbeatTimeout = event {
                    expectation.fulfill()
                }
            }
        }
        defer { streamTask.cancel() }


        // WHEN
        // HeartBeater 인스턴스를 직접 조작하기 어려우므로 Delegate 메서드를 직접 호출하여 시뮬레이션
        // (HeartBeater 객체는 더미로 전달)
        let dummyHeartBeater = await HeartBeater(repeatInterval: 1, timeout: 1)
        await advertiser.onTimeout(dummyHeartBeater)

        // THEN
        await fulfillment(of: [expectation], timeout: 1.0)
    }

    // MARK: - Helper Methods

    private func setupStreamingSession(with peerID: MCPeerID) throws -> MCSession {
        let context = "streaming".data(using: .utf8)
        let dummyAdvertiser = MCNearbyServiceAdvertiser(
            peer: peerID,
            discoveryInfo: nil,
            serviceType: "test"
        )

        var capturedSession: MCSession?
        advertiser.connectionManager.advertiser(
            dummyAdvertiser,
            didReceiveInvitationFromPeer: peerID,
            withContext: context
        ) { accept, session in
            XCTAssertTrue(accept)
            capturedSession = session
        }

        guard let session = capturedSession else {
            throw TestError.sessionNotCreated
        }
        return session
    }

    private func setupCommandSession(with peerID: MCPeerID) throws -> MCSession {
        let context = "command".data(using: .utf8)
        let dummyAdvertiser = MCNearbyServiceAdvertiser(
            peer: peerID,
            discoveryInfo: nil,
            serviceType: "test"
        )

        var capturedSession: MCSession?
        advertiser.connectionManager.advertiser(
            dummyAdvertiser,
            didReceiveInvitationFromPeer: peerID,
            withContext: context
        ) { accept, session in
            XCTAssertTrue(accept)
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
