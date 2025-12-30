//
//  MultipeerInvitation.swift
//  mirroringBooth
//
//  Created by Liam on 12/30/25.
//

import MultipeerConnectivity

struct MultipeerInvitation: Identifiable, Equatable {
    let id = UUID()
    let peerID: MCPeerID
    let handler: (Bool, MCSession?) -> Void
    
    static func == (lhs: MultipeerInvitation, rhs: MultipeerInvitation) -> Bool {
        lhs.peerID == rhs.peerID
    }
}
