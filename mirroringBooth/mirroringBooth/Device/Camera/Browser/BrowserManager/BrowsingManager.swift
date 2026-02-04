//
//  BrowsingManager.swift
//  mirroringBooth
//
//  Created by 윤대현 on 2026-02-04.
//

import MultipeerConnectivity
import OSLog

/// 기기 탐색을 담당하는 매니저
final class BrowsingManager: NSObject {

    private let logger = Logger.browsingManager
    private let browser: MCNearbyServiceBrowser
    private let peerID: MCPeerID
    private let streamManager: BrowserStreamManager

    /// 발견된 Peer 목록
    private(set) var discoveredPeers: [String: (peer: MCPeerID, type: DeviceType)] = [:]

    init(peerID: MCPeerID, serviceType: String, streamManager: BrowserStreamManager) {
        self.peerID = peerID
        self.streamManager = streamManager
        self.browser = MCNearbyServiceBrowser(peer: peerID, serviceType: serviceType)
        super.init()
        browser.delegate = self
    }

    func startSearching() {
        browser.stopBrowsingForPeers()
        browser.startBrowsingForPeers()
        logger.info("주변 기기를 검색합니다.")
    }

    func stopSearching() {
        browser.stopBrowsingForPeers()
        logger.info("주변 기기 검색을 중지합니다.")
    }

    /// 특정 기기에게 연결 초대를 전송합니다.
    func invitePeer(_ deviceID: String, to session: MCSession, withContext context: Data?, timeout: TimeInterval) {
        guard let (peer, _) = discoveredPeers[deviceID] else {
            logger.warning("[연결 실패] 기기를 찾을 수 없음 : \(deviceID)")
            return
        }
        browser.invitePeer(peer, to: session, withContext: context, timeout: timeout)
        logger.info("[\(deviceID)]에게 연결 요청을 전송했습니다.")
    }

    /// 특정 기기가 발견되었는지 확인합니다.
    func getPeer(for deviceID: String) -> (peer: MCPeerID, type: DeviceType)? {
        return discoveredPeers[deviceID]
    }
}

// MARK: - MCNearbyServiceBrowserDelegate

extension BrowsingManager: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser,
                 foundPeer peerID: MCPeerID,
                 withDiscoveryInfo info: [String: String]?) {
        logger.info("발견된 기기: \(peerID.displayName)")
        guard let deviceTypeString = info?["deviceType"],
              let deviceType = DeviceType.from(string: deviceTypeString)
        else { return }

        self.discoveredPeers[peerID.displayName] = (peer: peerID, type: deviceType)
        let device = NearbyDevice(
            id: peerID.displayName,
            state: .notConnected,
            type: deviceType
        )
        streamManager.yieldBrowsingEvent(.deviceFound(device))
    }

    func browser(_ browser: MCNearbyServiceBrowser,
                 lostPeer peerID: MCPeerID) {
        logger.info("사라진 기기: \(peerID.displayName)")
        let deviceType = self.discoveredPeers[peerID.displayName]?.type ?? .unknown
        self.discoveredPeers.removeValue(forKey: peerID.displayName)
        let device = NearbyDevice(
            id: peerID.displayName,
            state: .notConnected,
            type: deviceType
        )
        streamManager.yieldBrowsingEvent(.deviceLost(device))
    }
}
