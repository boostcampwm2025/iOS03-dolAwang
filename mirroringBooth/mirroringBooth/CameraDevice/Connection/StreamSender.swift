//
//  StreamSender.swift
//  mirroringBooth
//
//  Created by 이상유 on 2025-12-28.
//

import Foundation
import MultipeerConnectivity

/// 스트림 송신 측 (iPhone)
/// 다른 기기를 탐색하고 연결하여 스트림 데이터(비디오/사진)를 전송
@Observable
final class StreamSender: NSObject {

    /// 연결된 피어들의 상태 정보
    var connectionState: [String: String] = [:]
    /// 발견된 피어 목록
    var peers: [String] = []

    /// 촬영 요청 수신 콜백
    var onCaptureRequested: (() -> Void)?

    private let serviceType: String
    /// 현재 기기의 식별자
    private let identifier: MCPeerID
    /// Multipeer 연결 세션
    private let session: MCSession
    /// 서비스 탐색 (송신 측)
    private let browser: MCNearbyServiceBrowser
    /// 발견된 피어 ID 매핑
    private var discoveredPeers: [String: MCPeerID] = [:]

    init(serviceType: String = "mirroringbooth") {
        self.serviceType = serviceType
        self.identifier = MCPeerID(displayName: UIDevice.current.name)
        self.session = MCSession(
            peer: identifier,
            securityIdentity: nil,
            encryptionPreference: .none
        )
        self.browser = MCNearbyServiceBrowser(peer: identifier, serviceType: serviceType)

        super.init()
        setup()
    }

    private func setup() {
        session.delegate = self
        browser.delegate = self
    }

    func startBrowsing() {
        peers.removeAll()
        discoveredPeers.removeAll()
        browser.startBrowsingForPeers()
    }

    func stopBrowsing() {
        browser.stopBrowsingForPeers()
    }

    func invite(to id: String) {
        guard let peerID = discoveredPeers[id] else { return }
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 30)
    }

    func sendPacket(_ data: Data) {
        // 연결된 피어가 없으면 전송하지 않음
        guard !session.connectedPeers.isEmpty else {
            return
        }

        // 패킷 타입에 따라 전송 모드 결정
        // SPS/PPS와 Photo는 반드시 전달되어야 하므로 reliable 모드 사용
        // 프레임 데이터는 실시간성이 중요하므로 unreliable 모드 사용
        let sendMode: MCSessionSendDataMode = {
            guard data.count > 0 else { return .unreliable }

            let packetType = data[0]
            // SPS(0x01), PPS(0x02), Photo(0x05)인 경우 reliable 모드
            if packetType == 0x01 || packetType == 0x02 || packetType == 0x05 {
                return .reliable
            }
            return .unreliable
        }()

        do {
            try session.send(data, toPeers: session.connectedPeers, with: sendMode)
        } catch {
            print("Failed to send packet data: \(error)")
        }
    }

}

// MARK: - Session Delegate
extension StreamSender: MCSessionDelegate {

    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
        case .connected:
            connectionState[peerID.displayName] = "✅ \(peerID.displayName)와 연결 완료"
        case .connecting:
            connectionState[peerID.displayName] = "⏳ \(peerID.displayName)와 연결 중"
        case .notConnected:
            connectionState.removeValue(forKey: peerID.displayName)
        default:
            break
        }
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        // 수신된 데이터가 촬영 요청 패킷인지 확인
        guard let packet = DataPacket.deserialize(data),
              packet.type == .captureRequest else {
            return
        }

        // 촬영 요청 콜백 호출
        onCaptureRequested?()
    }

    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) { }

    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) { }

    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: (any Error)?) { }

}

// MARK: - Browser Delegate
extension StreamSender: MCNearbyServiceBrowserDelegate {

    func browser(
        _ browser: MCNearbyServiceBrowser,
        foundPeer peerID: MCPeerID,
        withDiscoveryInfo info: [String : String]?
    ) {
        let displayName = peerID.displayName
        discoveredPeers[displayName] = peerID
        guard !peers.contains(displayName) else { return }
        peers.append(displayName)
    }

    func browser(
        _ browser: MCNearbyServiceBrowser,
        lostPeer peerID: MCPeerID
    ) {

    }

}
