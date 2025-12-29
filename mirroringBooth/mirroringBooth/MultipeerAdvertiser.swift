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
    weak var delegate: AcceptInvitationDelegate?
    
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
}

extension MultipeerAdvertiser: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        Logger.multipeerAdvertiser.debug("📩 초대장 도착: \(peerID.displayName)")
        delegate?.didReceiveInvitation(
            session: session,
            invitationHandler: invitationHandler
        )
    }
}

protocol AcceptInvitationDelegate: AnyObject {
    func didReceiveInvitation(session: MCSession, invitationHandler: @escaping (Bool, MCSession?) -> Void)
}
