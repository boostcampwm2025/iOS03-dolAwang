//
//  MultipeerAdvertiser.swift
//  mirroringBooth
//
//  Created by Liam on 12/28/25.
//

import MultipeerConnectivity
import OSLog

final class MultipeerAdvertiser: NSObject {
    private let session: MCSession
    private let advertiser: MCNearbyServiceAdvertiser
    private weak var delegate: AcceptInvitationDelegate?
    
    init(session: MCSession) {
        self.session = session
        self.advertiser = MCNearbyServiceAdvertiser(
            peer: session.myPeerID,
            discoveryInfo: nil,
            serviceType: Config.serviceType
        )
        super.init()
        advertiser.delegate = self
        advertiser.startAdvertisingPeer()
    }
    
    func configure(delegate: AcceptInvitationDelegate) {
        self.delegate = delegate
    }
    
    func stop() {
        advertiser.stopAdvertisingPeer()
    }
}

extension MultipeerAdvertiser: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        Logger.multipeerAdvertiser.debug("📩 초대장 도착: \(peerID.displayName)")
        
        // Delegate 있으면 외부에서 초대 수락 여부 관리
        if let delegate {
            delegate.didReceiveInvitation(
                session: session,
                didReceiveInvitationFromPeer: peerID,
                invitationHandler: invitationHandler
            )
        } else {
            // Delegate 없으면 자동 수락
            invitationHandler(true, nil)
        }
    }
}

protocol AcceptInvitationDelegate: AnyObject {
    func didReceiveInvitation(session: MCSession, didReceiveInvitationFromPeer peerID: MCPeerID, invitationHandler: @escaping (Bool, MCSession?) -> Void)
}
