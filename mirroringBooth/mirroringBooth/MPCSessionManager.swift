//
//  MPCSessionManager.swift
//  MirroringBooth
//
//  Created by 최윤진 on 12/20/25.
//

import Foundation
import MultipeerConnectivity

enum P2PPacketType: UInt8 {
    case disconnect = 0
    case hevcFrame = 1
}

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

    // MARK: - Local (Published)
    var connectedPeers: [MCPeerID] = []
    var foundPeers: [MCPeerID] = []
    var isAdvertising: Bool = false
    var isBrowsing: Bool = false
    var connectionStateByDisplayName: [String: ConnectionState] = [:]

    // MARK: - P2P Payload (Published)
    var receivedHEVCFrameData: Data? = nil

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
            discoveryInfo: ["peerID": peerID],
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
        connectionStateByDisplayName.removeAll()

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
        connectionStateByDisplayName.removeAll()
    }

    func invite(_ peerID: MCPeerID) {
        guard let session = self.session,
              let browser = self.browser else { return }

        DispatchQueue.main.async {
            self.connectionStateByDisplayName[peerID.displayName] = .connecting
        }
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 15)
    }

    func disconnect(_ peerID: MCPeerID) {
        guard let session else { return }

        let packetData = Self.makePacket(type: .disconnect)
        try? session.send(packetData, toPeers: [peerID], with: .reliable)

        session.cancelConnectPeer(peerID)
    }
}

extension MPCSessionManager {
    // MARK: - Packet Utilities
    private static func makePacket(type: P2PPacketType, body: Data? = nil) -> Data {
        let bodyCount = body?.count ?? 0

        var bodyLength = UInt32(bodyCount).littleEndian
        var packetData = Data(bytes: &bodyLength, count: 4)
        packetData.append(type.rawValue)

        if let bodyValue: Data = body {
            packetData.append(bodyValue)
        }

        return packetData
    }

    private static func parsePacket(_ packetData: Data) -> (type: P2PPacketType, body: Data)? {
        guard 5 <= packetData.count else { return nil }

        let lengthData = packetData.prefix(4)
        let typeByte = packetData[4]

        let bodyLength = lengthData.withUnsafeBytes { rawBufferPointer in
            rawBufferPointer.load(as: UInt32.self)
        }.littleEndian

        let expectedTotalLength = 5 + Int(bodyLength)
        guard expectedTotalLength <= packetData.count else { return nil }

        let bodyData = packetData.subdata(in: 5..<(5 + Int(bodyLength)))
        guard let packetType = P2PPacketType(rawValue: typeByte) else { return nil }

        return (type: packetType, body: bodyData)
    }

    // MARK: - P2P Send
    func sendHEVCFrameData(_ data: Data) {
        guard let session = self.session,
              session.connectedPeers.isEmpty == false else { return }

        let packetData = Self.makePacket(type: .hevcFrame, body: data)

        try? session.send(packetData, toPeers: session.connectedPeers, with: .unreliable)
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
    ) {
        guard let parsed = Self.parsePacket(data) else { return }

        switch parsed.type {
        case .disconnect:
            DispatchQueue.main.async {
                self.connectedPeers.removeAll { $0.displayName == peerID.displayName }
                self.connectionStateByDisplayName[peerID.displayName] = .notConnected
            }
        case .hevcFrame:
            DispatchQueue.main.async {
                self.receivedHEVCFrameData = parsed.body
            }
        }
    }

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
