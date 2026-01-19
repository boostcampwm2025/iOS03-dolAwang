//
//  Browser.swift
//  mirroringBooth
//
//  Created by Liam on 1/19/26.
//

import MultipeerConnectivity
import OSLog

final class Browser: NSObject {
    private let browser: MCNearbyServiceBrowser
    private var discoveredPeers: [String: (peer: MCPeerID, type: DeviceType)] = [:]

    var onDeviceFound: ((NearbyDevice) -> Void)?
    var onDeviceLost: ((NearbyDevice) -> Void)?

    init(serviceType: String = "mirroringbooth", peerID: MCPeerID) {
        browser = MCNearbyServiceBrowser(peer: peerID, serviceType: serviceType)
        super.init()
        browser.delegate = self
    }

    func startSearching() {
        browser.startBrowsingForPeers()
        Logger.browser.info("주변 기기를 검색합니다.")
    }

    func stopSearching() {
        browser.stopBrowsingForPeers()
        Logger.browser.info("주변 기기 검색을 중지합니다.")
    }

    func connect(to deviceID: String, session: MCSession, withContext data: Data?) {
        guard let (peer, _) = discoveredPeers[deviceID] else {
            Logger.browser.warning("[연결 실패] 기기를 찾을 수 없음 : \(deviceID)")
            return
        }
        browser.invitePeer(
            peer,
            to: session,
            withContext: data,
            timeout: 10
        )
    }

    func getDeviceType(of peerID: MCPeerID) -> DeviceType {
        let type = discoveredPeers[peerID.displayName]?.type ?? .unknown
        discoveredPeers[peerID.displayName] = (
            peer: peerID,
            type: type
        )
        return type
    }
}

// MARK: - Browser Delegate
extension Browser: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser,
                 foundPeer peerID: MCPeerID,
                 withDiscoveryInfo info: [String: String]?) {
        Logger.browser.info("발견된 기기: \(peerID.displayName)")
        guard let deviceTypeString = info?["deviceType"],
              let deviceType = DeviceType.from(string: deviceTypeString)
        else { return }

        self.discoveredPeers[peerID.displayName] = (peer: peerID, type: deviceType)
        let device = NearbyDevice(
            id: peerID.displayName,
            state: .notConnected,
            type: deviceType
        )
        DispatchQueue.main.async {
            self.onDeviceFound?(device)
        }
    }

    func browser(_ browser: MCNearbyServiceBrowser,
                 lostPeer peerID: MCPeerID) {
        Logger.browser.info("사라진 기기: \(peerID.displayName)")
        let deviceType = self.discoveredPeers[peerID.displayName]?.type ?? .unknown
        self.discoveredPeers.removeValue(forKey: peerID.displayName)
        let device = NearbyDevice(
            id: peerID.displayName,
            state: .notConnected,
            type: deviceType
        )
        DispatchQueue.main.async {
            self.onDeviceLost?(device)
        }
    }
}
