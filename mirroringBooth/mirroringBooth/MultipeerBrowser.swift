//
//  MultipeerBrowser.swift
//  mirroringBooth
//
//  Created by Liam on 12/29/25.
//

import MultipeerConnectivity
import OSLog

final class MultipeerBrowser: NSObject {
    private let session: MCSession
    private let browser: MCNearbyServiceBrowser
    var foundPeers: [MCPeerID] = []
    
    init(session: MCSession) {
        self.session = session
        self.browser = MCNearbyServiceBrowser(
            peer: session.myPeerID,
            serviceType: Config.serviceType
        )
        super.init()
        browser.delegate = self
        browser.startBrowsingForPeers()
    }
}

extension MultipeerBrowser: MCNearbyServiceBrowserDelegate {
    // 기기를 발견했을 때 호출됨
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        if !self.foundPeers.contains(peerID) {
            self.foundPeers.append(peerID)
            Logger.multipeerBrowser.debug("🔭 기기 발견: \(peerID.displayName)")
        }
        browser.invitePeer(peerID, to: self.session, withContext: nil, timeout: 10)
    }
    
    // 기기가 사라졌을 때
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        if let index = self.foundPeers.firstIndex(of: peerID) {
            _ = self.foundPeers.remove(at: index)
            Logger.multipeerBrowser.debug("👋 기기 사라짐: \(peerID.displayName)")
        }
    }
}
