//
//  VideoReceiver.swift
//  mirroringBooth
//
//  Created by 이상유 on 2025-12-28.
//

import Foundation
import MultipeerConnectivity

/// 비디오 수신 측 (iPad/Mac)
/// 서비스를 광고하고 연결 요청을 수락하여 비디오 데이터를 수신
@Observable
final class VideoReceiver: NSObject {

    /// 연결된 피어들의 상태 정보
    var connectionState: Bool = false

    /// 비디오 데이터 수신 콜백
    var onVideoReceived: ((Data) -> Void)?

    private let serviceType: String
    /// 현재 기기의 식별자
    private let identifier: MCPeerID
    /// Multipeer 연결 세션
    private let session: MCSession
    /// 서비스 광고 (수신 측)
    private let advertiser: MCNearbyServiceAdvertiser

    init(serviceType: String = "mirroringbooth") {
        self.serviceType = serviceType
        self.identifier = MCPeerID(displayName: UIDevice.current.name)
        self.session = MCSession(
            peer: identifier,
            securityIdentity: nil,
            encryptionPreference: .none
        )
        self.advertiser = MCNearbyServiceAdvertiser(peer: identifier, discoveryInfo: nil, serviceType: serviceType)

        super.init()
        setup()
    }

    private func setup() {
        session.delegate = self
        advertiser.delegate = self
    }

    func startAdvertising() {
        advertiser.startAdvertisingPeer()
    }

    func stopAdvertising() {
        advertiser.stopAdvertisingPeer()
    }

}

// MARK: - Session Delegate
extension VideoReceiver: MCSessionDelegate {

    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
        case .connected:
            connectionState = true
        case .notConnected:
            connectionState = false
        default:
            break
        }
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        // 수신된 비디오 데이터를 디코더로 전달
        onVideoReceived?(data)
    }

    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) { }

    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) { }

    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: (any Error)?) { }

}

// MARK: - Advertiser Delegate
extension VideoReceiver: MCNearbyServiceAdvertiserDelegate {

    func advertiser(
        _ advertiser: MCNearbyServiceAdvertiser,
        didReceiveInvitationFromPeer peerID: MCPeerID,
        withContext context: Data?,
        invitationHandler: @escaping (Bool, MCSession?) -> Void
    ) {
        invitationHandler(true, session)
    }

}
