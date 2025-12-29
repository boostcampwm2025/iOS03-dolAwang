//
//  MultipeerManager.swift
//  mirroringBooth
//
//  Created by Liam on 12/25/25.
//

import Combine
import MultipeerConnectivity
import OSLog

final class MultipeerManager: NSObject, ObservableObject {
    private var session: MCSession
    private var advertiser: MultipeerAdvertiser?
    private var browser: MultipeerBrowser?
    
    @Published var mainPeer: MCPeerID?
    @Published var secondaryPeer: MCPeerID?
    @Published var sessionState: MCSessionState = .notConnected
    
    override init() {
        let peerID = MCPeerID(displayName: UIDevice.current.name)
        self.session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        super.init()
        self.session.delegate = self
    }
    
    func startAdvertising(delegate: AcceptInvitationDelegate?) {
        advertiser = MultipeerAdvertiser(session: session)
        if let delegate {
            advertiser?.configure(delegate: delegate)
        }
    }
    
    func startBrowsing() {
        browser = MultipeerBrowser(session: session)
    }
    
    func stopDiscovery() {
        advertiser?.stop()
        browser?.stop()
    }
    
    func stopSession() {
        session.disconnect()
    }
}

extension MultipeerManager: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        self.sessionState = state
        
        switch state {
        case .connected:
            Logger.multipeerManager.debug("✅ 연결 성공! 상대방: \(peerID.displayName)")
            if let mainPeer {
                secondaryPeer = peerID
            } else {
                mainPeer = peerID
            }
            
        case .connecting:
            Logger.multipeerManager.debug("🟡 연결 시도 중...")
            
        case .notConnected:
            Logger.multipeerManager.debug("🔴 연결 끊김")
            if let mainPeer, peerID == mainPeer {
                self.mainPeer = nil
            } else if let secondaryPeer, peerID == secondaryPeer {
                self.secondaryPeer = nil
            }
            
        @unknown default:
            break
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {}
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}
