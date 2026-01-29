//
//  Browser.swift
//  mirroringBooth
//
//  Created by 이상유 on 2025-12-28.
//

import Combine
import MultipeerConnectivity
import OSLog

/// 스트림 송신 측 (iPhone)
/// 다른 기기를 탐색하고 연결하여 스트림 데이터(비디오/사진)를 전송
final class Browser: NSObject {
    enum MirroringDeviceCommand: String {
        case navigateToSelectModeWithRemote
        case navigateToSelectModeWithoutRemote
        case switchSelectModeView
        case allPhotosStored // 사진 10장 모두 저장 완료
        case onUpdateCaptureCount   //  리모트 기기에서 카메라 캡처 요청 보내기
        case heartBeat
        case captureEffect
    }

    enum RemoteDeviceCommand: String {
        case navigateToRemoteCapture
        case navigateToRemoteComplete
        case navigateToRemoteConnected
        case navigateToHome
        case noticeIsRemoteDevice
        case heartBeat
    }

    enum SessionType: String {
        case streaming
        case command
    }

    private let logger = Logger.browser

    private let serviceType: String
    private let peerID: MCPeerID
    private var mirroringSession: MCSession?
    var isMirroringSessionActive: Bool { mirroringSession?.connectedPeers.count == 1 }
    private var mirroringCommandSession: MCSession?
    private var remoteSession: MCSession?
    var isRemoteSessionActive: Bool { remoteSession?.connectedPeers.count == 1 }
    private let browser: MCNearbyServiceBrowser
    let mirroringHeartBeater: HeartBeater
    var remoteHeartBeater: HeartBeater?

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

    /// 촬영 명령 수신 콜백
    var onCaptureCommand: (() -> Void)?

    /// 일괄 전송 시작 명령 수신 콜백
    var onStartTransferCommand = PassthroughSubject<Void, Never>()

    /// 사진 보내기 성공 콜백
    var onSendPhoto: (() -> Void)?

    /// 원격 모드 설정 명령 수신 콜백
    var onRemoteModeCommand: (() -> Void)?

    /// 타이머 모드 선택 명령 수신 콜백
    var onSelectedTimerModeCommand: (() -> Void)?

    /// heartbeat 메시지 타임아웃
    var onHeartbeatTimeout: (() -> Void)?
    var onRemoteHeartbeatTimeout: (() -> Void)?

    /// 현재 기기가 비디오 송신 역할인지 여부 (iPhone만 송신)
    var isVideoSender: Bool {
        UIDevice.current.userInterfaceIdiom == .phone
    }

    init(serviceType: String = "mirroringbooth") {
        self.serviceType = serviceType
        self.myDeviceName = PeerNameGenerator.makeDisplayName(isRandom: false, with: UIDevice.current.deviceType)
        self.peerID = MCPeerID(displayName: myDeviceName)
        self.browser = MCNearbyServiceBrowser(peer: peerID, serviceType: serviceType)
        self.mirroringHeartBeater = HeartBeater(repeatInterval: 1.0, timeout: 2.5)

        super.init()
        browser.delegate = self
        mirroringHeartBeater.delegate = self
    }

    private func createRemoteHeartBeater() {
        self.remoteHeartBeater = HeartBeater(repeatInterval: 1.0, timeout: 2.5)
        remoteHeartBeater?.delegate = self
    }

    func startSearching() {
        browser.stopBrowsingForPeers()
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

        var targetSession: MCSession?
        switch useType {
        case .mirroring:
            targetMirroringDeviceID = deviceID
            // 세션은 invite 직전에 생성함.
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
            mirroringSession?.delegate = self
            mirroringCommandSession?.delegate = self
            // 커맨드 세션에 대해 먼저 연결을 요청합니다.
            targetSession = mirroringCommandSession
        case .remote:
            targetRemoteDeviceID = deviceID
            self.remoteSession = MCSession(
                peer: peerID,
                securityIdentity: nil,
                encryptionPreference: .none
            )
            remoteSession?.delegate = self
            targetSession = remoteSession
        }
        guard let targetSession else { return }

        browser.invitePeer(
            peer,
            to: targetSession,
            withContext: SessionType.command.rawValue.data(using: .utf8),
            timeout: 10
        )
        logger.info("연결 요청 전송: \(deviceID) (\(useType == .mirroring ? "미러링" : "리모트"))")
    }

    /// 카메라 캡쳐 액션을 실행합니다.
    func capturePhoto() {
        self.onCaptureCommand?()
        self.sendCommand(.onUpdateCaptureCount)
        self.sendCommand(.captureEffect)
    }

    /// 미러링 세션에 연결된 피어에게 스트림 데이터를 전송합니다.
    func sendStreamData(_ data: Data) {
        guard let mirroringSession else { return }
        let connectedPeers = mirroringSession.connectedPeers
        guard !connectedPeers.isEmpty else {
            logger.warning("스트림 전송 실패: 연결된 피어가 없습니다")
            return
        }

        do {
            try mirroringSession.send(data, toPeers: connectedPeers, with: .unreliable)
        } catch {
            logger.warning("스트림 데이터 전송 실패 : \(error.localizedDescription)")
        }
    }

    /// 미러링 세션에 연결된 피어에게 사진 리소스를 전송합니다.
    func sendPhotoResource(_ data: Data) {
        guard let mirroringSession else { return }
        guard let mirroringPeer = mirroringSession.connectedPeers.first else {
            logger.warning("사진 전송 실패: 미러링 세션에 연결된 피어가 없습니다.")
            return
        }

        let photoID = UUID()
        let fileName = "\(photoID.uuidString).jpg"

        // 임시 파일 생성
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        do {
            try data.write(to: tempURL)
            logger.info("사진 전송 시작: \(fileName) (\(data.count) bytes)")

            mirroringSession.sendResource(
                at: tempURL,
                withName: fileName,
                toPeer: mirroringPeer
            ) { error in
                if let error {
                    self.logger.warning("사진 전송 실패 : \(error.localizedDescription)")
                } else {
                    self.onSendPhoto?()
                    self.logger.info("사진 전송 완료: \(fileName)")
                }

                // 전송 완료 후 임시 파일 삭제
                try? FileManager.default.removeItem(at: tempURL)
            }

        } catch {
            logger.warning("임시 파일 생성 실패 : \(error.localizedDescription)")
        }
    }

    /// 미러링 기기에게 명령을 전송합니다.
    func sendCommand(_ command: MirroringDeviceCommand) {
        guard let mirroringCommandSession, let data = command.rawValue.data(using: .utf8) else { return }
        let connectedPeers = mirroringCommandSession.connectedPeers
        guard !connectedPeers.isEmpty else {
            logger.warning("명령 전송 실패: commandSession에 연결된 피어가 없습니다")
            return
        }

        do {
            try mirroringCommandSession.send(
                data,
                toPeers: connectedPeers,
                with: .reliable
            )
            if command != .heartBeat {
                logger.info("명령 전송 성공: \(command.rawValue)")
            }
        } catch {
            logger.warning("명령 전송 실패: \(error.localizedDescription)")
        }
    }

    /// 리모트 기기에게 명령을 전송합니다.
    func sendRemoteCommand(_ command: RemoteDeviceCommand) {
        guard let data = command.rawValue.data(using: .utf8) else { return }

        guard let connectedPeers = remoteSession?.connectedPeers,
              !connectedPeers.isEmpty else {
            logger.warning("명령 전송 실패: remoteSession에 연결된 피어가 없습니다")
            return
        }

        do {
            try remoteSession?.send(
                data,
                toPeers: connectedPeers,
                with: .reliable
            )
            logger.info("리모트 명령 전송 성공: \(command.rawValue)")
        } catch {
            logger.warning("리모트 명령 전송 실패: \(error.localizedDescription)")
        }
    }

    /// 모든 세션의 연결을 해제합니다.
    func disconnect() {
        // disconnect의 호출이 세션을 아예 nil로 변경.
        mirroringSession?.disconnect()
        mirroringCommandSession?.disconnect()
        remoteSession?.disconnect()
        mirroringSession = nil
        mirroringCommandSession = nil
        remoteSession = nil
        targetMirroringDeviceID = nil
        targetRemoteDeviceID = nil
        mirroringHeartBeater.stop()
        remoteHeartBeater?.stop()
        logger.info("모든 연결 해제")
    }

    /// 특정 타겟 타입의 연결만 해제합니다.
    func disconnect(useType: DeviceUseType) {
        switch useType {
        case .mirroring:
            mirroringSession?.disconnect()
            mirroringCommandSession?.disconnect()
            mirroringSession = nil
            mirroringCommandSession = nil
            targetMirroringDeviceID = nil
            mirroringHeartBeater.stop()
            logger.info("미러링 연결 해제")
        case .remote:
            remoteSession?.disconnect()
            remoteSession = nil
            targetRemoteDeviceID = nil
            remoteHeartBeater?.stop()
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

        // 명령 세션이 연결되면 미러링 세션을 초대합니다.
        if let mirroringSession, sessionTypeLabel == "미러링 명령", newState == .connected {
            logger.info("미러링 커맨드 세션 연결 완료, 미러링 세션 초대 시작")
            browser.invitePeer(
                peerID,
                to: mirroringSession,
                withContext: SessionType.streaming.rawValue.data(using: .utf8),
                timeout: 10
            )
            return
        }

        let deviceType = discoveredPeers[peerID.displayName]?.type ?? .unknown
        discoveredPeers[peerID.displayName] = (peer: peerID, type: deviceType)
        let device = NearbyDevice(id: peerID.displayName, state: newState, type: deviceType)

        if session === mirroringSession, state == .connected {
            mirroringHeartBeater.start()
        } else if session === remoteSession, state == .connected {
            sendRemoteCommand(.noticeIsRemoteDevice)
            if remoteHeartBeater == nil {
                createRemoteHeartBeater()
            }
            remoteHeartBeater?.start()
        }

        DispatchQueue.main.async {
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
        let isMirroringCommandTarget = (session === mirroringCommandSession)
            && (peerID.displayName == targetMirroringDeviceID)
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
    ) {
        if session === mirroringCommandSession || session === remoteSession {
            executeCommand(data: data)
        } else if session === mirroringSession {
            logger.info("스트림 세션에서 데이터 수신: \(data.count) bytes")
        }
    }

    // MARK: - 명령 수신 처리

    private func executeCommand(data: Data) {
        guard let command = String(data: data, encoding: .utf8) else { return }
        if let type = Advertiser.CameraDeviceCommand(rawValue: command) {
            switch type {
            case .capturePhoto:
                DispatchQueue.main.async {
                    self.capturePhoto()
                }
            case .startTransfer:
                DispatchQueue.main.async {
                    self.onStartTransferCommand.send()
                    self.sendRemoteCommand(.navigateToRemoteComplete)
                }
            case .setRemoteMode:
                DispatchQueue.main.async {
                    self.onRemoteModeCommand?()
                    self.sendRemoteCommand(.navigateToRemoteCapture)
                }
            case .selectedTimerMode:
                DispatchQueue.main.async {
                    self.onSelectedTimerModeCommand?()
                    self.sendRemoteCommand(.navigateToHome)
                }
            case .heartBeat:
                mirroringHeartBeater.beat()
            case .remoteHeartBeat:
                remoteHeartBeater?.beat()
            case .stopHeartBeat:
                mirroringHeartBeater.stop()
                remoteHeartBeater?.stop()
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
