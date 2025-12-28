//
//  MultipeerManager.swift
//  mirroringBooth
//
//  Created by 윤대현 on 12/29/25.
//

import MultipeerConnectivity
import Observation
import os

@Observable
final class MultipeerManager: NSObject {
    private let logger = AppLogger.make(for: MultipeerManager.self)

    private let serviceType: String
    private let peerID: MCPeerID
    private let session: MCSession
    private let advertiser: MCNearbyServiceAdvertiser
    private let browser: MCNearbyServiceBrowser

    /// 발견된 기기 정보
    private struct DiscoveredPeer {
        let peerID: MCPeerID
        var state: ConnectionState = .notConnected
    }

    private var discoveredPeers: [String: DiscoveredPeer] = [:]

    var isSearching: Bool = false

    /// View 표시용 기기 목록
    var nearbyDevices: [NearbyDevice] {
        discoveredPeers.map {
            NearbyDevice(
                id: $0.key,
                name: $0.value.peerID.displayName,
                state: $0.value.state
            )
        }
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

    func connect(to device: NearbyDevice) {
        guard let peer = discoveredPeers[device.id] else {
            logger.warning("[연결 실패] 기기를 찾을 수 없음 : \(device.name)")
            return
        }

        browser.invitePeer(peer.peerID, to: session, withContext: nil, timeout: 10)
        logger.info("연결 요청 전송: \(device.name)")
    }
}

// MARK: - MCSessionDelegate
// 피어 간 연결 상태의 변화 및 데이터 수신을 처리합니다.
extension MultipeerManager: MCSessionDelegate {
    /// 피어의 연결 상태 변화를 감지합니다.
    func session(
        _ session: MCSession,
        peer peerID: MCPeerID,
        didChange state: MCSessionState
    ) {
        let deviceID = peerID.displayName
        let newState: ConnectionState

        switch state {
        case .notConnected:
            newState = .notConnected
            logger.info("[\(deviceID)] 연결 안됨")
        case .connecting:
            newState = .connecting
            logger.info("[\(deviceID)] 연결 중..")
        case .connected:
            newState = .connected
            logger.info("[\(deviceID)] 연결됨 ✅")
        @unknown default:
            newState = .notConnected
            logger.warning("[\(deviceID)] 알 수 없는 상태")
        }

        discoveredPeers[deviceID]?.state = newState
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
        // 임시적으로 수신된 초대가 자동으로 수락되도록 작성했습니다.
        invitationHandler(true, session)
    }
}

// MARK: - MCNearbyServiceBrowserDelegate
// 주변에서 광고 중인 피어를 탐색하고 피어를 발견하거나 사라지는 이벤트를 처리합니다.
extension MultipeerManager: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser,
                 foundPeer peerID: MCPeerID,
                 withDiscoveryInfo info: [String : String]?) {
        discoveredPeers[peerID.displayName] = DiscoveredPeer(peerID: peerID)
        logger.info("발견된 기기: \(peerID.displayName)")
    }

    func browser(_ browser: MCNearbyServiceBrowser,
                 lostPeer peerID: MCPeerID) {
        discoveredPeers.removeValue(forKey: peerID.displayName)
        logger.info("사라진 기기: \(peerID.displayName)")
    }
}

