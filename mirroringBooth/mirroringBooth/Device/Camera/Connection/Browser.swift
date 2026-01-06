//
//  Browser.swift
//  mirroringBooth
//
//  Created by 이상유 on 2025-12-28.
//

import Combine
import MultipeerConnectivity
import Observation
import os

/// 스트림 송신 측 (iPhone)
/// 다른 기기를 탐색하고 연결하여 스트림 데이터(비디오/사진)를 전송
@Observable
final class Browser: NSObject {

    private let logger = AppLogger.make(for: CameraManager.self)

    private let serviceType: String
    private let peerID: MCPeerID
    private let session: MCSession
    private let browser: MCNearbyServiceBrowser

    private var discoveredPeers: [NearbyDevice: MCPeerID] = [:]

    var isSearching: Bool = false

    /// 연결된 피어가 있는지 여부
    var isConnected: Bool = false

    /// 현재 기기가 비디오 송신 역할인지 여부 (iPhone만 송신)
    var isVideoSender: Bool {
        UIDevice.current.userInterfaceIdiom == .phone
    }

    init(serviceType: String = "mirroringbooth") {
        self.serviceType = serviceType
        self.peerID = MCPeerID(displayName: UIDevice.current.name)
        self.session = MCSession(
            peer: peerID,
            securityIdentity: nil,
            encryptionPreference: .required
        )
        self.browser = MCNearbyServiceBrowser(peer: peerID, serviceType: serviceType)

        super.init()
        setup()
    }

    private func setup() {
        session.delegate = self
        browser.delegate = self
    }

    func startSearching() {
        browser.startBrowsingForPeers()
        isSearching = true
        logger.info("주변 기기를 검색합니다.")
    }

    func stopSearching() {
        browser.stopBrowsingForPeers()
        isSearching = false
        logger.info("주변 기기 검색을 중지합니다.")
    }

    func toggleSearching() {
        if isSearching {
            stopSearching()
        } else {
            startSearching()
        }
    }

    /// 특정 기기에게 연결 요청을 전송합니다.
    func connect(to device: NearbyDevice) {
        guard let peer = discoveredPeers[device] else {
            logger.warning("[연결 실패] 기기를 찾을 수 없음 : \(device.id)")
            return
        }

        browser.invitePeer(peer, to: session, withContext: nil, timeout: 10)
        logger.info("연결 요청 전송: \(device.id)")
    }

    /// 연결된 피어에게 스트림 데이터를 전송합니다.
    func sendStreamData(_ data: Data) {
        let connectedPeers = session.connectedPeers
        guard !connectedPeers.isEmpty else { return }

        do {
            try session.send(data, toPeers: connectedPeers, with: .unreliable)
        } catch {
            logger.warning("스트림 데이터 전송 실패 : \(error.localizedDescription)")
        }
    }

    /// 연결된 피어에게 사진 리소스를 전송합니다.
    func sendPhotoResource(_ data: Data) {
        guard let peer = session.connectedPeers.first else {
            logger.warning("사진 전송 실패: 연결된 피어가 없습니다.")
            return
        }

        let photoID = UUID()
        let fileName = "\(photoID.uuidString).jpg"

        // 임시 파일 생성
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(fileName)

        do {
            try data.write(to: tempURL)

            session.sendResource(
                at: tempURL,
                withName: fileName,
                toPeer: peer
            ) { error in
                if let error {
                    self.logger.warning("사진 전송 실패 : \(error.localizedDescription)")
                }

                // 전송 완료 후 임시 파일 삭제
                try? FileManager.default.removeItem(at: tempURL)
            }

        } catch {
            logger.warning("임시 파일 생성 실패 : \(error.localizedDescription)")
        }
    }

    /// 연결된 특정 기기와 연결을 해제합니다.
    func disconnect(from device: NearbyDevice) {
        guard discoveredPeers[device] != nil else { return }
        // 임시적으로 세션 자체를 끊습니다.
        session.disconnect()
        logger.info("연결 해제: \(device.id)")
    }

}

// MARK: - Session Delegate
extension Browser: MCSessionDelegate {

    func session(
        _ session: MCSession,
        peer peerID: MCPeerID,
        didChange state: MCSessionState
    ) {
        let newState: ConnectionState

        switch state {
        case .notConnected:
            newState = .notConnected
            logger.info("[\(peerID.displayName)] 연결 안됨")
        case .connecting:
            newState = .connecting
            logger.info("[\(peerID.displayName)] 연결 중..")
        case .connected:
            newState = .connected
            logger.info("[\(peerID.displayName)] 연결됨 ✅")
        @unknown default:
            newState = .notConnected
            logger.warning("[\(peerID.displayName)] 알 수 없는 상태")
        }

        DispatchQueue.main.async {
            let device = NearbyDevice(id: peerID.displayName, state: newState)
            self.discoveredPeers[device] = peerID
            self.isConnected = !session.connectedPeers.isEmpty
        }
    }

    func session(
        _ session: MCSession,
        didReceive data: Data,
        fromPeer peerID: MCPeerID
    ) {}

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
    ) {}

    func session(
        _ session: MCSession,
        didFinishReceivingResourceWithName resourceName: String,
        fromPeer peerID: MCPeerID,
        at localURL: URL?,
        withError error: (any Error)?
    ) {}

}

// MARK: - Browser Delegate
extension Browser: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser,
                 foundPeer peerID: MCPeerID,
                 withDiscoveryInfo info: [String: String]?) {
        logger.info("발견된 기기: \(peerID.displayName)")
        DispatchQueue.main.async {
            let device = NearbyDevice(id: peerID.displayName, state: .notConnected)
            self.discoveredPeers[device] = peerID
        }
    }

    func browser(_ browser: MCNearbyServiceBrowser,
                 lostPeer peerID: MCPeerID) {
        logger.info("사라진 기기: \(peerID.displayName)")
        DispatchQueue.main.async {
            let device = NearbyDevice(id: peerID.displayName, state: .notConnected)
            self.discoveredPeers.removeValue(forKey: device)
        }
    }
}
