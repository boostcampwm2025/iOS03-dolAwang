//
//  Browser.swift
//  mirroringBooth
//
//  Created by 이상유 on 2025-12-28.
//

import MultipeerConnectivity
import Observation
import OSLog

/// 스트림 송신 측 (iPhone)
/// 다른 기기를 탐색하고 연결하여 스트림 데이터(비디오/사진)를 전송
final class Browser: NSObject {

    private let logger = Logger.browser

    private let serviceType: String
    private let peerID: MCPeerID
    private let mirroringSession: MCSession
    private let remoteSession: MCSession
    private let browser: MCNearbyServiceBrowser

    private var discoveredPeers: [String: (peer: MCPeerID, type: DeviceType)] = [:]

    /// 현재 연결 시도 중인 미러링 디바이스 ID
    private var targetMirroringDeviceID: String?

    /// 현재 연결 시도 중인 리모트 디바이스 ID
    private var targetRemoteDeviceID: String?

    var onDeviceFound: ((NearbyDevice) -> Void)?

    var onDeviceLost: ((NearbyDevice) -> Void)?

    var onDeviceConnected: ((NearbyDevice) -> Void)?

    /// 현재 기기가 비디오 송신 역할인지 여부 (iPhone만 송신)
    var isVideoSender: Bool {
        UIDevice.current.userInterfaceIdiom == .phone
    }

    init(serviceType: String = "mirroringbooth") {
        self.serviceType = serviceType
        self.peerID = MCPeerID(displayName: UIDevice.current.name)
        self.mirroringSession = MCSession(
            peer: peerID,
            securityIdentity: nil,
            encryptionPreference: .required
        )
        self.remoteSession = MCSession(
            peer: peerID,
            securityIdentity: nil,
            encryptionPreference: .required
        )
        self.browser = MCNearbyServiceBrowser(peer: peerID, serviceType: serviceType)

        super.init()
        setup()
    }

    deinit {
        stopSearching()
    }

    private func setup() {
        mirroringSession.delegate = self
        remoteSession.delegate = self
        browser.delegate = self
    }

    func startSearching() {
        browser.startBrowsingForPeers()
        logger.info("주변 기기를 검색합니다.")
    }

    private func stopSearching() {
        browser.stopBrowsingForPeers()
        logger.info("주변 기기 검색을 중지합니다.")
    }

    /// 특정 기기에게 연결 요청을 전송합니다.
    func connect(to deviceID: String, as targetType: ConnectionTargetType) {
        guard let (peer, _) = discoveredPeers[deviceID] else {
            logger.warning("[연결 실패] 기기를 찾을 수 없음 : \(deviceID)")
            return
        }

        let targetSession: MCSession
        switch targetType {
        case .mirroring:
            targetMirroringDeviceID = deviceID
            targetSession = mirroringSession
        case .remote:
            targetRemoteDeviceID = deviceID
            targetSession = remoteSession
        }

        browser.invitePeer(peer, to: targetSession, withContext: nil, timeout: 10)
        logger.info("연결 요청 전송: \(deviceID) (\(targetType == .mirroring ? "미러링" : "리모트"))")
    }

    /// 미러링 세션에 연결된 피어에게 스트림 데이터를 전송합니다.
    func sendStreamData(_ data: Data) {
        let connectedPeers = mirroringSession.connectedPeers
        guard !connectedPeers.isEmpty else { return }

        do {
            try mirroringSession.send(data, toPeers: connectedPeers, with: .unreliable)
        } catch {
            logger.warning("스트림 데이터 전송 실패 : \(error.localizedDescription)")
        }
    }

    /// 미러링 세션에 연결된 피어에게 사진 리소스를 전송합니다.
    func sendPhotoResource(_ data: Data) {
        guard let mirroringPeer = mirroringSession.connectedPeers.first else {
            logger.warning("사진 전송 실패: 미러링 세션에 연결된 피어가 없습니다.")
            return
        }

        let photoID = UUID()
        let fileName = "\(photoID.uuidString).jpg"

        // 임시 파일 생성
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(fileName)

        do {
            try data.write(to: tempURL)

            mirroringSession.sendResource(
                at: tempURL,
                withName: fileName,
                toPeer: mirroringPeer
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

    /// 모든 세션의 연결을 해제합니다.
    func disconnect() {
        mirroringSession.disconnect()
        remoteSession.disconnect()
        targetMirroringDeviceID = nil
        targetRemoteDeviceID = nil
        logger.info("모든 연결 해제")
    }

    /// 특정 타겟 타입의 연결만 해제합니다.
    func disconnect(targetType: ConnectionTargetType) {
        switch targetType {
        case .mirroring:
            mirroringSession.disconnect()
            targetMirroringDeviceID = nil
            logger.info("미러링 연결 해제")
        case .remote:
            remoteSession.disconnect()
            targetRemoteDeviceID = nil
            logger.info("리모트 연결 해제")
        }
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
        let sessionTypeLabel: String

        // 어떤 세션에서 상태 변경이 발생했는지 확인
        if session === mirroringSession {
            sessionTypeLabel = "미러링"
        } else if session === remoteSession {
            sessionTypeLabel = "리모트"
        } else {
            sessionTypeLabel = "알 수 없음"
        }

        switch state {
        case .notConnected:
            newState = .notConnected
            logger.info("[\(peerID.displayName)] 연결 안됨 (\(sessionTypeLabel))")
        case .connecting:
            newState = .connecting
            logger.info("[\(peerID.displayName)] 연결 중.. (\(sessionTypeLabel))")
        case .connected:
            newState = .connected
            logger.info("[\(peerID.displayName)] 연결됨 ✅ (\(sessionTypeLabel))")
        @unknown default:
            newState = .notConnected
            logger.warning("[\(peerID.displayName)] 알 수 없는 상태 (\(sessionTypeLabel))")
        }

        // 상태가 변경된 peerID를 discoveredPeers에 저장하고, Store에 알린다.
        // 기존에 저장된 type 정보를 유지하거나, 없으면 .unknown으로 설정
        let deviceType = self.discoveredPeers[peerID.displayName]?.type ?? .unknown
        self.discoveredPeers[peerID.displayName] = (peer: peerID, type: deviceType)
        let device = NearbyDevice(id: peerID.displayName, state: newState, type: deviceType)

        DispatchQueue.main.async {
            self.onDeviceFound?(device)

            // 연결 성공 시, 해당 타겟 디바이스인 경우에만 콜백 호출
            if newState == .connected {
                let isMirroringTarget = session === self.mirroringSession &&
                                         peerID.displayName == self.targetMirroringDeviceID
                let isRemoteTarget = session === self.remoteSession &&
                                      peerID.displayName == self.targetRemoteDeviceID
                let isTargetDevice = isMirroringTarget || isRemoteTarget

                if isTargetDevice {
                    self.onDeviceConnected?(device)
                }
            }
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
        guard let deviceTypeString = info?["deviceType"],
              let deviceType = DeviceType.from(string: deviceTypeString)
        else { return }

        self.discoveredPeers[peerID.displayName] = (peer: peerID, type: deviceType)
        let device = NearbyDevice(
            id: peerID.displayName,
            state: .notConnected,
            type: deviceType
        )
        DispatchQueue.main.async {
            self.onDeviceFound?(device)
        }
    }

    func browser(_ browser: MCNearbyServiceBrowser,
                 lostPeer peerID: MCPeerID) {
        logger.info("사라진 기기: \(peerID.displayName)")
        let deviceType = self.discoveredPeers[peerID.displayName]?.type ?? .unknown
        self.discoveredPeers.removeValue(forKey: peerID.displayName)
        let device = NearbyDevice(
            id: peerID.displayName,
            state: .notConnected,
            type: deviceType
        )
        DispatchQueue.main.async {
            self.onDeviceLost?(device)
        }
    }
}
