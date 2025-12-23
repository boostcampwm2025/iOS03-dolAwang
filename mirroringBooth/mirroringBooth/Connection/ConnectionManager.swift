//
//  ConnectionManager.swift
//  mirroringBooth
//
//  Created by 이상유 on 2025-12-24.
//

import Foundation
import MultipeerConnectivity

@Observable
final class ConnectionManager: NSObject {

    var connectionState: String = ""
    var peers: [String] = []

    private let serviceType: String
    private let identifier: MCPeerID
    private let session: MCSession
    private let advertiser: MCNearbyServiceAdvertiser
    private let browser: MCNearbyServiceBrowser
    
    init(serviceType: String = "MirroringBooth") {
        self.serviceType = serviceType
        self.identifier = MCPeerID(displayName: UIDevice.current.name)
        self.session = MCSession(peer: identifier)
        self.advertiser = MCNearbyServiceAdvertiser(peer: identifier, discoveryInfo: nil, serviceType: serviceType)
        self.browser = MCNearbyServiceBrowser(peer: identifier, serviceType: serviceType)
        
        super.init()
        setup()
    }
    
    private func setup() {
        session.delegate = self
        advertiser.delegate = self
        browser.delegate = self
    }

    func startBrowsing() {
        peers.removeAll()
        advertiser.startAdvertisingPeer()
        browser.startBrowsingForPeers()
    }

    func stopBrowsing() {
        advertiser.stopAdvertisingPeer()
        browser.stopBrowsingForPeers()
    }

    func invite(to id: String) {
        let peerID = MCPeerID(displayName: id)
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 10)
    }
}

// MARK: - Session Delegate
extension ConnectionManager: MCSessionDelegate {
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
        case .connected:
            connectionState = "✅ \(peerID.displayName)와 연결 완료"
        case .connecting:
            connectionState = "⏳ \(peerID.displayName)와 연결 중"
        case .notConnected:
            connectionState = "❌ \(peerID.displayName)와 연결 끊김"
        default:
            break
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: (any Error)?) {
        
    }
    
}


// MARK: - Advertiser Delegate

extension ConnectionManager: MCNearbyServiceAdvertiserDelegate {
    
    func advertiser(
        _ advertiser: MCNearbyServiceAdvertiser,
        didReceiveInvitationFromPeer peerID: MCPeerID,
        withContext context: Data?,
        invitationHandler: @escaping (Bool, MCSession?) -> Void
    ) {
        invitationHandler(true, session)
    }
    
}

// MARK: - Browser Delegate

extension ConnectionManager: MCNearbyServiceBrowserDelegate {
    
    func browser(
        _ browser: MCNearbyServiceBrowser,
        foundPeer peerID: MCPeerID,
        withDiscoveryInfo info: [String : String]?
    ) {
        peers.append(peerID.displayName)
    }
    
    func browser(
        _ browser: MCNearbyServiceBrowser,
        lostPeer peerID: MCPeerID
    ) {
        
    }
    
}
