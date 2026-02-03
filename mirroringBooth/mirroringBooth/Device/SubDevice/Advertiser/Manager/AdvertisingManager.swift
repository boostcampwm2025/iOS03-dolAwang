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
    func connectionManager(_ manager: AdvertisingManager, didCreateSession session: MCSession, type: String)
}

final class AdvertisingManager: NSObject {
    private let advertiser: MCNearbyServiceAdvertiser
    private var isBlockingInvitation: Bool = false

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

    func startSearching() {
        isBlockingInvitation = false
        advertiser.startAdvertisingPeer()
        Logger.advertisingManager.info("광고를 시작합니다.")
    }

    func stopSearching(onlyRefuse: Bool = false) {
        if onlyRefuse {
            isBlockingInvitation = true
            return
        }
        advertiser.stopAdvertisingPeer()
        Logger.advertisingManager.info("광고를 중단합니다.")
    }
}

extension AdvertisingManager: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser,
                    didReceiveInvitationFromPeer peerID: MCPeerID,
                    withContext context: Data?,
                    invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        guard let context,
              let type = String(data: context, encoding: .utf8) else {
            Logger.advertisingManager.warning("초대 수신 실패: context 파싱 불가 - \(peerID.displayName)")
            invitationHandler(false, nil)
            return
        }

        // 이미 연결된 피어인지 확인
        let isAlreadyConnected = connectedPeersCheck?(peerID) ?? false
        guard isBlockingInvitation == false || isAlreadyConnected else {
            invitationHandler(false, nil)
            return
        }
        Logger.advertisingManager.info("초대 수신: \(peerID.displayName)(타입: \(type))")

        // 세션 생성
        let session: MCSession
        if type == "streaming" {
            session = MCSession(
                peer: advertiser.myPeerID,
                securityIdentity: nil,
                encryptionPreference: .required
            )
        } else if type == "command" {
            session = MCSession(
                peer: advertiser.myPeerID,
                securityIdentity: nil,
                encryptionPreference: .none
            )
        } else {
            invitationHandler(false, nil)
            return
        }
        // 델리게이트에게 알림 (Advertiser가 세션을 저장하고 Delegate를 설정하도록)
        delegate?.connectionManager(self, didCreateSession: session, type: type)
        invitationHandler(true, session)
    }
}
