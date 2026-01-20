//
//  Advertiser.swift
//  mirroringBooth
//
//  Created by 이상유 on 2025-12-28.
//

import Foundation
import MultipeerConnectivity
import OSLog

/// 서비스를 광고하고 연결 요청을 수락하여 스트림 데이터(비디오/사진)를 수신
final class Advertiser: NSObject {

    private let logger = Logger.advertiser

    private let serviceType: String
    private let peerID: MCPeerID
    private var session: MCSession?
    private var commandSession: MCSession?
    private let advertiser: MCNearbyServiceAdvertiser
    private let photoCacheManager: PhotoCacheManager
    private let heartBeater: HeartBeater
    let myDeviceName: String

    /// 수신된 스트림 데이터 콜백
    var onReceivedStreamData: ((Data) -> Void)?

    var navigateToSelectModeCommandCallBack: ((_ isRemoteEnable: Bool) -> Void)?
    var navigateToRemoteCaptureCallBack: (() -> Void)?
    var navigateToRemoteCompleteCallBack: (() -> Void)?

    /// 카메라 기기에게 보내는 명령
    enum CameraDeviceCommand: String {
        case capturePhoto  // 사진 촬영
        case startTransfer // 일괄 전송 시작
        case setRemoteMode // 원격 촬영 모드 설정
        case selectedTimerMode // 타이머 모드 선택
        case heartBeat // 세션 생존 확인
        case stopHeartBeat // heartbeat 종료
    }

    /// 사진 수신 완료 콜백 (1장마다 호출)
    var onPhotoReceived: (() -> Void)?

    /// 캡쳐 요청 카운트 콜백 (촬영기기에서 전송)
    var onUpdateCaptureCount: (() -> Void)?

    /// 10장 모두 저장 완료 콜백 (촬영기기에서 전송)
    var onAllPhotosStored: (() -> Void)?

    /// heartbeat 메시지 타임아웃
    var onHeartBeatTimeout: (() -> Void)?

    init(serviceType: String = "mirroringbooth", photoCacheManager: PhotoCacheManager) {
        self.serviceType = serviceType
        self.myDeviceName = PeerNameGenerator.makeDisplayName(isRandom: true, with: UIDevice.current.deviceType)
        self.peerID = MCPeerID(displayName: myDeviceName)

        let myDeviceType: String = {
        #if os(iOS)
            if UIDevice.current.userInterfaceIdiom == .phone { return "iPhone" }
            if UIDevice.current.userInterfaceIdiom == .pad {
                // build는 iOS이지만 실행 기기가 Mac인지 확인
                if ProcessInfo.processInfo.isiOSAppOnMac {
                    return "Mac"
                }
                return "iPad"
            }
            return "iOS"
        #elseif os(macOS)
            return "Mac"
        #else
            return "Unknown"
        #endif
        }()

        self.advertiser = MCNearbyServiceAdvertiser(
            peer: peerID,
            discoveryInfo: ["deviceType": myDeviceType],
            serviceType: serviceType
        )
        self.photoCacheManager = photoCacheManager
        self.heartBeater = HeartBeater(repeatInterval: 1.0, timeout: 2.5)

        super.init()
        advertiser.delegate = self
        heartBeater.delegate = self
    }

    func setupCacheManager() {
        Task {
            await photoCacheManager.startNewSession()
        }
    }

    func startSearching() {
        advertiser.startAdvertisingPeer()
        logger.info("광고를 시작합니다.")
    }

    func stopSearching() {
        advertiser.stopAdvertisingPeer()
        logger.info("광고를 중단합니다.")
    }

    /// 세션과 연결을 해제합니다.
    func disconnect() {
        session?.disconnect()
        commandSession?.disconnect()
        session = nil
        commandSession = nil
        logger.info("연결 해제: \(self.peerID.displayName)")
    }

    func stopHeartBeating() {
        sendCommand(.stopHeartBeat)
        heartBeater.stop()
    }

    /// 연결된 카메라 기기(iPhone)에게 명령을 전송합니다.
    func sendCommand(_ command: CameraDeviceCommand) {
        guard let commandSession, let commandData = command.rawValue.data(using: .utf8) else { return }
        let connectedPeers = commandSession.connectedPeers
        guard !connectedPeers.isEmpty else {
            logger.warning("명령 전송 실패: commandSession에 연결된 피어가 없습니다")
            return
        }

        do {
            try commandSession.send(commandData, toPeers: connectedPeers, with: .reliable)
            logger.info("촬영 명령 전송: \(command.rawValue)")
        } catch {
            logger.warning("명령 전송 실패: \(error.localizedDescription)")
        }
    }

    private func executeCommand(data: Data) {
        guard let command = String(data: data, encoding: .utf8) else { return }

        if let mirroringDeviceCommand = Browser.MirroringDeviceCommand(rawValue: command) {
            handleMirroringDeviceCommand(mirroringDeviceCommand)
            return
        }

        if let remoteDeviceCommand = Browser.RemoteDeviceCommand(rawValue: command) {
            handleRemoteDeviceCommand(remoteDeviceCommand)
            return
        }
    }

    private func handleMirroringDeviceCommand(_ mirroringDeviceCommand: Browser.MirroringDeviceCommand) {
        switch mirroringDeviceCommand {
        case .navigateToSelectModeWithRemote:
            guard let navigateToSelectModeCommandCallBack else { return }
            DispatchQueue.main.async {
                navigateToSelectModeCommandCallBack(true)
            }
        case .navigateToSelectModeWithoutRemote:
            guard let navigateToSelectModeCommandCallBack else { return }
            DispatchQueue.main.async {
                navigateToSelectModeCommandCallBack(false)
            }
        case .allPhotosStored:
            DispatchQueue.main.async {
                self.onAllPhotosStored?()
            }
        case .onUpdateCaptureCount:
            DispatchQueue.main.async {
                self.onUpdateCaptureCount?()
            }
        case .heartBeat:
            heartBeater.beat()
        }
    }

    private func handleRemoteDeviceCommand(_ remoteDeviceCommand: Browser.RemoteDeviceCommand) {
        switch remoteDeviceCommand {
        case .navigateToRemoteCapture:
            guard let navigateToRemoteCaptureCallBack else { return }
            DispatchQueue.main.async {
                navigateToRemoteCaptureCallBack()
            }
        case .navigateToRemoteComplete:
            DispatchQueue.main.async {
                self.navigateToRemoteCompleteCallBack?()
            }
        }
    }
}

// MARK: - Session Delegate
extension Advertiser: MCSessionDelegate {

    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        if case .notConnected = state {
            disconnect()
        }
        if session === self.session, state == .connected {
            heartBeater.start()
        }
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        if session === self.session {
            // 스트림 세션에서 수신
            onReceivedStreamData?(data)
        } else if session === commandSession {
            // 명령 세션에서 수신
            executeCommand(data: data)
        }
    }

    func session(
        _ session: MCSession,
        didReceive stream: InputStream,
        withName streamName: String,
        fromPeer peerID: MCPeerID
    ) { }

    /// 파일 전송이 시작되었음을 알리고 진행 상태를 알립니다.
    func session(
        _ session: MCSession,
        didStartReceivingResourceWithName resourceName: String,
        fromPeer peerID: MCPeerID,
        with progress: Progress
    ) {
        logger.info("사진 수신 시작: \(resourceName) from \(peerID.displayName)")
    }

    /// 파일 전송이 완료되었거나 실패했음을 알립니다.
    func session(
        _ session: MCSession,
        didFinishReceivingResourceWithName resourceName: String,
        fromPeer peerID: MCPeerID,
        at localURL: URL?,
        withError error: Error?
    ) {
        if let error {
            logger.warning("사진 수신 실패: \(error.localizedDescription)")
            return
        }

        guard let localURL else {
            logger.warning("사진 수신 실패: URL 없음")
            return
        }
        // 사진 캐싱
        Task {
            do {
                try await photoCacheManager.savePhotoData(localURL: localURL)
            } catch {
                logger.error("사진 저장 실패: \(error.localizedDescription)")
            }
        }
        /// 사진 수신 완료
        DispatchQueue.main.async {
            self.onPhotoReceived?()
        }
    }
}

// MARK: - Advertiser Delegate
// 주변 기기로부터 들어오는 연결 초대를 수신한 뒤 승인 및 거절을 처리합니다.
extension Advertiser: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser,
                    didReceiveInvitationFromPeer peerID: MCPeerID,
                    withContext context: Data?,
                    invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        guard let context,
              let type = String(data: context, encoding: .utf8) else {
            logger.warning("초대 수신 실패: context 파싱 불가 - \(peerID.displayName)")
            invitationHandler(false, nil)
            return
        }

        logger.info("초대 수신: \(peerID.displayName)(타입: \(type))")
        if type == "streaming" {
            // invite를 수락하는 시점에 session을 생성
            self.session = MCSession(
                peer: self.peerID,
                securityIdentity: nil,
                encryptionPreference: .required
            )
            session?.delegate = self
            invitationHandler(true, session)
        } else if type == "command" {
            self.commandSession = MCSession(
                peer: self.peerID,
                securityIdentity: nil,
                encryptionPreference: .none
            )
            commandSession?.delegate = self
            invitationHandler(true, commandSession)
        } else {
            invitationHandler(false, nil)
        }
    }
}
