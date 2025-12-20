//
//  MPCSessionManager.swift
//  MirroringBooth
//
//  Created by 최윤진 on 12/20/25.
//

import Combine
import Foundation
import MultipeerConnectivity

@Observable
final class MPCSessionManager: NSObject {
    // MARK: - Connection
    enum ConnectionState: String {
        case connected
        case connecting
        case notConnected
    }

    // MARK: - Private
    private let serviceType = "mirroring-booth"
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?
    private var session: MCSession?

    // MARK: - Published
    var connectedPeers: [MCPeerID] = []
    var foundPeers: [MCPeerID] = []
    var isAdvertising: Bool = false
    var isBrowsing: Bool = false
    var connectionStateByPeerDisplayName: [String: ConnectionState] = [:]

    func start(_ peerID: String) {
        guard session == nil else { return }

        let peer = MCPeerID(displayName: peerID)
        session = MCSession(
            peer: peer,
            securityIdentity: nil,
            encryptionPreference: .required
        )
        session?.delegate = self

        advertiser = MCNearbyServiceAdvertiser(
            peer: peer,
            discoveryInfo: nil,
            serviceType: serviceType
        )
        advertiser?.delegate = self

        browser = MCNearbyServiceBrowser(
            peer: peer,
            serviceType: serviceType
        )
        browser?.delegate = self

        foundPeers.removeAll()
        connectedPeers.removeAll()
        connectionStateByPeerDisplayName.removeAll()

        isAdvertising = true
        isBrowsing = true
        advertiser?.startAdvertisingPeer()
        browser?.startBrowsingForPeers()
    }

    func stop() {
        isAdvertising = false
        isBrowsing = false

        advertiser?.stopAdvertisingPeer()
        advertiser = nil

        browser?.stopBrowsingForPeers()
        browser = nil

        session?.disconnect()
        session = nil

        foundPeers.removeAll()
        connectedPeers.removeAll()
        connectionStateByPeerDisplayName.removeAll()
    }

    func invite(_ peerID: MCPeerID) {
        guard let session = self.session,
              let browser = self.browser else { return }

        DispatchQueue.main.async {
            self.connectionStateByPeerDisplayName[peerID.displayName] = .connecting
        }
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 15)
    }

    func disconnect(_ peerID: MCPeerID) {
        guard let session = self.session else { return }

        session.cancelConnectPeer(peerID)
    }
}

extension MPCSessionManager: MCSessionDelegate {
    func session(
        _ session: MCSession,
        peer peerID: MCPeerID,
        didChange state: MCSessionState
    ) {
        DispatchQueue.main.async {
            switch state {
            case .connected:
                self.connectionStateByPeerDisplayName[peerID.displayName] = .connected
            case .connecting:
                self.connectionStateByPeerDisplayName[peerID.displayName] = .connecting
            case .notConnected:
                self.connectionStateByPeerDisplayName[peerID.displayName] = .notConnected
            @unknown default:
                self.connectionStateByPeerDisplayName[peerID.displayName] = .notConnected
            }
            self.connectedPeers = session.connectedPeers
        }
    }
    
    func session(
        _ session: MCSession,
        didReceive data: Data,
        fromPeer peerID: MCPeerID
    ) { }

    func session(
        _ session: MCSession,
        didReceive stream: InputStream,
        withName streamName: String,
        fromPeer peerID: MCPeerID
    ) { }

    func session(
        _ session: MCSession,
        didStartReceivingResourceWithName resourceName: String,
        fromPeer peerID: MCPeerID,
        with progress: Progress
    ) { }

    func session(
        _ session: MCSession,
        didFinishReceivingResourceWithName resourceName: String,
        fromPeer peerID: MCPeerID,
        at localURL: URL?,
        withError error: (any Error)?
    ) { }
}

extension MPCSessionManager: MCNearbyServiceAdvertiserDelegate {
    func advertiser(
        _ advertiser: MCNearbyServiceAdvertiser,
        didReceiveInvitationFromPeer peerID: MCPeerID,
        withContext context: Data?,
        invitationHandler: @escaping (Bool, MCSession?) -> Void
    ) {
        guard let session = self.session else {
            invitationHandler(false, nil)
            return
        }

        DispatchQueue.main.async {
            self.connectionStateByPeerDisplayName[peerID.displayName] = .connecting
        }
        invitationHandler(true, session)
    }
}

extension MPCSessionManager: MCNearbyServiceBrowserDelegate {
    func browser(
        _ browser: MCNearbyServiceBrowser,
        foundPeer peerID: MCPeerID,
        withDiscoveryInfo info: [String : String]?
    ) {
        DispatchQueue.main.async {
            if !self.foundPeers.contains(where: { $0.displayName == peerID.displayName }) {
                self.foundPeers.append(peerID)
            }
        }
    }

    func browser(
        _ browser: MCNearbyServiceBrowser,
        lostPeer peerID: MCPeerID
    ) {
        DispatchQueue.main.async {
            self.foundPeers.removeAll { $0.displayName == peerID.displayName }
        }
    }
}
