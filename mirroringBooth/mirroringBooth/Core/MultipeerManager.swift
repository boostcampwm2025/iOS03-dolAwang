//
//  MultipeerManager.swift
//  mirroringBooth
//
//  Created by 윤대현 on 12/29/25.
//

import MultipeerConnectivity
import Observation
import os

/// View용 순수 데이터 모델
struct NearbyDevice: Hashable, Identifiable {
    let id: String
    let name: String
}

@Observable
final class MultipeerManager: NSObject {
    private let logger = AppLogger.make(for: MultipeerManager.self)

    private let serviceType: String
    private let peerID: MCPeerID
    private let session: MCSession
    private let advertiser: MCNearbyServiceAdvertiser
    private let browser: MCNearbyServiceBrowser
    /// 발견된 기기 목록
    private var discoveredPeers: [String: MCPeerID] = [:]

    var isSearching: Bool = false
    /// View에 표시할 기기 목록
    var nearbyDevices: [NearbyDevice] {
        discoveredPeers.map { NearbyDevice(id: $0.key, name: $0.value.displayName) }
    }

    init(serviceType: String = "mirroring-booth") {
        self.serviceType = serviceType
        self.peerID = MCPeerID(displayName: UIDevice.current.name)
        self.session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .none)
        self.advertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: nil, serviceType: serviceType)
        self.browser = MCNearbyServiceBrowser(peer: peerID, serviceType: serviceType)

        super.init()
        session.delegate = self
        advertiser.delegate = self
        browser.delegate = self
    }

    func startSearching() {
        advertiser.startAdvertisingPeer()
        browser.startBrowsingForPeers()
        isSearching = true
        logger.info("주변 기기를 검색합니다.")
    }

    func stopSearching() {
        advertiser.stopAdvertisingPeer()
        browser.stopBrowsingForPeers()
        isSearching = false
        logger.info("주변 기기 검색을 중지합니다.")
    }

    func toggleSearching() {
        if isSearching {
            stopSearching()
        } else {
            startSearching()
        }
    }
}

// MARK: - MCSessionDelegate
// 피어 간 연결 상태의 변화 및 데이터 수신을 처리합니다.
extension MultipeerManager: MCSessionDelegate {
    /// 피어의 연결 상태 변화를 감지합니다.
    ///
    /// `.notConnected`
    /// `.connecting`
    /// `.connected`
    func session(
        _ session: MCSession,
        peer peerID: MCPeerID,
        didChange state: MCSessionState
    ) {
        logger.debug("세션 상태 변경: \(peerID.displayName), \(state.rawValue)")
    }

    /// 연결된 피어로부터 Data 타입의 메세지를 수신합니다.
    func session(
        _ session: MCSession,
        didReceive data: Data,
        fromPeer peerID: MCPeerID
    ) {

    }

    /// 실시간 스트림(InputStream)을 수신합니다.
    func session(
        _ session: MCSession,
        didReceive stream: InputStream,
        withName streamName: String,
        fromPeer peerID: MCPeerID
    ) {

    }

    /// 파일 전송이 시작되었음을 알리고 진행 상태를 알립니다.
    func session(
        _ session: MCSession,
        didStartReceivingResourceWithName resourceName: String,
        fromPeer peerID: MCPeerID,
        with progress: Progress
    ) {

    }

    /// 파일 전송이 완료되었거나 실패했음을 알립니다.
    func session(
        _ session: MCSession,
        didFinishReceivingResourceWithName resourceName: String,
        fromPeer peerID: MCPeerID,
        at localURL: URL?,
        withError error: (any Error)?
    ) {

    }
}

// MARK: - MCNearbyServiceAdvertiserDelegate
// 주변 기기로부터 들어오는 연결 초대를 수신한 뒤 승인 및 거절을 처리합니다.
extension MultipeerManager: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser,
                    didReceiveInvitationFromPeer peerID: MCPeerID,
                    withContext context: Data?,
                    invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        logger.info("초대 수신: \(peerID.displayName)")
    }
}

// MARK: - MCNearbyServiceBrowserDelegate
// 주변에서 광고 중인 피어를 탐색하고 피어를 발견하거나 사라지는 이벤트를 처리합니다.
extension MultipeerManager: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser,
                 foundPeer peerID: MCPeerID,
                 withDiscoveryInfo info: [String : String]?) {
        discoveredPeers[peerID.displayName] = peerID
        logger.info("발견된 기기: \(peerID.displayName)")
    }

    func browser(_ browser: MCNearbyServiceBrowser,
                 lostPeer peerID: MCPeerID) {
        discoveredPeers.removeValue(forKey: peerID.displayName)
        logger.info("사라진 기기: \(peerID.displayName)")
    }
}
