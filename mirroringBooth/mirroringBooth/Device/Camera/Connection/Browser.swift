//
//  Browser.swift
//  mirroringBooth
//
//  Created by 이상유 on 2025-12-28.
//

import MultipeerConnectivity
import OSLog

/// 스트림 송신 측 (iPhone)
/// 다른 기기를 탐색하고 연결하여 스트림 데이터(비디오/사진)를 전송
final class Browser: NSObject {
    enum MirroringDeviceCommand: String {
        case navigateToSelectMode
    }

    enum SessionType: String {
        case streaming
        case command
    }

    private let logger = Logger.browser

    private let serviceType: String
    private let peerID: MCPeerID
    private let mirroringSession: MCSession
    private let mirroringCommandSession: MCSession
    private let remoteSession: MCSession
    private let browser: MCNearbyServiceBrowser

    private var discoveredPeers: [String: (peer: MCPeerID, type: DeviceType)] = [:]

    /// 현재 연결 시도 중인 미러링 디바이스 ID
    private var targetMirroringDeviceID: String?

    /// 현재 연결 시도 중인 리모트 디바이스 ID
    private var targetRemoteDeviceID: String?

    let myDeviceName: String

    var onDeviceFound: ((NearbyDevice) -> Void)?

    var onDeviceLost: ((NearbyDevice) -> Void)?

    var onDeviceConnected: ((NearbyDevice) -> Void)?

    var onDeviceConnectionFailed: (() -> Void)?

    /// 현재 기기가 비디오 송신 역할인지 여부 (iPhone만 송신)
    var isVideoSender: Bool {
        UIDevice.current.userInterfaceIdiom == .phone
    }

    init(serviceType: String = "mirroringbooth") {
        self.serviceType = serviceType
        self.myDeviceName = PeerNameGenerator.makeDisplayName(isRandom: false, with: UIDevice.current.name)
        self.peerID = MCPeerID(displayName: myDeviceName)
        self.mirroringSession = MCSession(
            peer: peerID,
            securityIdentity: nil,
            encryptionPreference: .required
        )
        self.mirroringCommandSession = MCSession(
            peer: peerID,
            securityIdentity: nil,
            encryptionPreference: .none
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

    private func setup() {
        mirroringSession.delegate = self
        mirroringCommandSession.delegate = self
        remoteSession.delegate = self
        browser.delegate = self
    }

    func startSearching() {
        browser.startBrowsingForPeers()
        logger.info("주변 기기를 검색합니다.")
    }

    func stopSearching() {
        browser.stopBrowsingForPeers()
        logger.info("주변 기기 검색을 중지합니다.")
    }

    /// 특정 기기에게 연결 요청을 전송합니다.
    func connect(to deviceID: String, as useType: DeviceUseType) {
        guard let (peer, _) = discoveredPeers[deviceID] else {
            logger.warning("[연결 실패] 기기를 찾을 수 없음 : \(deviceID)")
            return
        }

        let targetSession: MCSession
        switch useType {
        case .mirroring:
            targetMirroringDeviceID = deviceID
            targetSession = mirroringSession
        case .remote:
            targetRemoteDeviceID = deviceID
            targetSession = remoteSession
        }

        browser.invitePeer(
            peer,
            to: targetSession,
            withContext: SessionType.streaming.rawValue.data(using: .utf8),
            timeout: 10
        )
        if useType == .mirroring {
            browser.invitePeer(
                peer,
                to: mirroringCommandSession,
                withContext: SessionType.command.rawValue.data(using: .utf8),
                timeout: 10
            )
        }
        logger.info("연결 요청 전송: \(deviceID) (\(useType == .mirroring ? "미러링" : "리모트"))")
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

    func sendCommand(_ command: MirroringDeviceCommand) {
        guard let data = command.rawValue.data(using: .utf8) else { return }
        let connectedPeers = mirroringCommandSession.connectedPeers
        do {
            switch command {
            case .navigateToSelectMode:
                try mirroringCommandSession.send(
                    data,
                    toPeers: connectedPeers,
                    with: .reliable
                )
            }
        } catch {
            logger.warning("명령 전송 실패: \(error.localizedDescription)")
        }
    }

    /// 모든 세션의 연결을 해제합니다.
    func disconnect() {
        mirroringSession.disconnect()
        mirroringCommandSession.disconnect()
        remoteSession.disconnect()
        targetMirroringDeviceID = nil
        targetRemoteDeviceID = nil
        logger.info("모든 연결 해제")
    }

    /// 특정 타겟 타입의 연결만 해제합니다.
    func disconnect(useType: DeviceUseType) {
        switch useType {
        case .mirroring:
            mirroringSession.disconnect()
            mirroringCommandSession.disconnect()
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
        let sessionTypeLabel = getSessionTypeLabel(for: session)
        let newState = logAndConvertState(state, for: peerID.displayName, sessionType: sessionTypeLabel)

        let deviceType = discoveredPeers[peerID.displayName]?.type ?? .unknown
        discoveredPeers[peerID.displayName] = (peer: peerID, type: deviceType)
        let device = NearbyDevice(id: peerID.displayName, state: newState, type: deviceType)

        DispatchQueue.main.async {
            self.onDeviceFound?(device)
            self.handleConnectionStateChange(newState, device: device, session: session, peerID: peerID)
        }
    }

    private func getSessionTypeLabel(for session: MCSession) -> String {
        if session === mirroringSession {
            return "미러링"
        } else if session === mirroringCommandSession {
            return "미러링 명령"
        } else if session === remoteSession {
            return "리모트"
        } else {
            return "알 수 없음"
        }
    }

    private func logAndConvertState(
        _ state: MCSessionState,
        for deviceName: String,
        sessionType: String
    ) -> ConnectionState {
        switch state {
        case .notConnected:
            logger.info("[\(deviceName)] 연결 안됨 (\(sessionType))")
            return .notConnected
        case .connecting:
            logger.info("[\(deviceName)] 연결 중.. (\(sessionType))")
            return .connecting
        case .connected:
            logger.info("[\(deviceName)] 연결됨 ✅ (\(sessionType))")
            return .connected
        @unknown default:
            logger.warning("[\(deviceName)] 알 수 없는 상태 (\(sessionType))")
            return .notConnected
        }
    }

    private func handleConnectionStateChange(
        _ state: ConnectionState,
        device: NearbyDevice,
        session: MCSession,
        peerID: MCPeerID
    ) {
        let isMirroringTarget = session === mirroringSession && peerID.displayName == targetMirroringDeviceID
        let isMirroringCommandTarget = session === mirroringSession && peerID.displayName == targetMirroringDeviceID
        let isRemoteTarget = session === remoteSession && peerID.displayName == targetRemoteDeviceID

        guard isMirroringTarget || isMirroringCommandTarget || isRemoteTarget else { return }

        switch state {
        case .connected:
            onDeviceConnected?(device)
        case .notConnected:
            onDeviceConnectionFailed?()
            if isMirroringTarget || isMirroringCommandTarget {
                targetMirroringDeviceID = nil
            }
            if isRemoteTarget {
                targetRemoteDeviceID = nil
            }
        case .connecting:
            break
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
