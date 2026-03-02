//
//  AdvertisingManager.swift
//  mirroringBooth
//
//  Created by Liam on 2/3/26.
//

import Foundation
import MultipeerConnectivity
import OSLog

protocol ConnectionManagerDelegate: AnyObject {
    func connectionManager(_ manager: AdvertisingManager, didCreateSession session: MCSession)
}

final class AdvertisingManager: NSObject {
    private let advertiser: MCNearbyServiceAdvertiser
    private var isBlockingInvitation: Bool = false
    private var isAdvertising: Bool = false

    weak var delegate: ConnectionManagerDelegate?
    var connectedPeersCheck: ((MCPeerID) -> Bool)? // 특정 피어가 이미 연결되어 있는지 확인하는 클로저

    init(serviceType: String, peerID: MCPeerID, discoveryInfo: [String: String]?) {
        self.advertiser = MCNearbyServiceAdvertiser(
            peer: peerID,
            discoveryInfo: discoveryInfo,
            serviceType: serviceType
        )
        super.init()
        self.advertiser.delegate = self
    }

    func startAdvertising() {
        isBlockingInvitation = false
        isAdvertising = true
        advertiser.startAdvertisingPeer()
        Logger.advertisingManager.info("광고를 시작합니다.")
    }

    func stopAdvertising(onlyRefuse: Bool = false) {
        if onlyRefuse {
            isBlockingInvitation = true
            return
        }
        isAdvertising = false
        advertiser.stopAdvertisingPeer()
        Logger.advertisingManager.info("광고를 중단합니다.")
    }

    func startIfAdvertising() {
        if isAdvertising {
            advertiser.startAdvertisingPeer( )
        }
    }

    func stopIfAdvertising() {
        if isAdvertising {
            advertiser.stopAdvertisingPeer( )
        }
    }
}

extension AdvertisingManager: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser,
                    didReceiveInvitationFromPeer peerID: MCPeerID,
                    withContext context: Data?,
                    invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        // 이미 연결된 피어인지 확인
        let isAlreadyConnected = connectedPeersCheck?(peerID) ?? false
        guard isBlockingInvitation == false || isAlreadyConnected else {
            invitationHandler(false, nil)
            return
        }
        Logger.advertisingManager.info("초대 수신: \(peerID.displayName)")

        advertiser.stopAdvertisingPeer()

        // 세션 생성
        let session = MCSession(
            peer: advertiser.myPeerID,
            securityIdentity: nil,
            encryptionPreference: .required
        )
        // 델리게이트에게 알림 (Advertiser가 세션을 저장하고 Delegate를 설정하도록)
        delegate?.connectionManager(self, didCreateSession: session)
        invitationHandler(true, session)
    }
}
