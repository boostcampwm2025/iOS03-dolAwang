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
    private var isBlockingInvitation: Bool = false
    var advertiserType: DeviceUseType = .mirroring // heartbeat 메시지 종류 구분을 위해 추가
    let myDeviceName: String

    private let videoContinuation: AsyncStream<FrameReceivingEvents>.Continuation
    let videoStream: AsyncStream<FrameReceivingEvents>

    private let advertisingContinuation: AsyncStream<AdvertiserEvents>.Continuation
    let advertisingStream: AsyncStream<AdvertiserEvents>

    private let modeSelectionContinuation: AsyncStream<ModeSelectionEvents>.Continuation
    let modeSelectionStream: AsyncStream<ModeSelectionEvents>

    private let remoteConnectedViewContinuation: AsyncStream<RemoteConnectedViewEvents>.Continuation
    let remoteConnectedViewStream: AsyncStream<RemoteConnectedViewEvents>

    private let remoteCaptureViewContinuation: AsyncStream<RemoteCaptureViewEvents>.Continuation
    let remoteCaptureViewStream: AsyncStream<RemoteCaptureViewEvents>

    private let streamingStoreContinuation: AsyncStream<StreamingStoreEvents>.Continuation
    let streamingStoreStream: AsyncStream<StreamingStoreEvents>

    /// 카메라 기기에게 보내는 명령
    enum CameraDeviceCommand: String {
        case capturePhoto  // 사진 촬영
        case startTransfer // 일괄 전송 시작
        case setRemoteMode // 원격 촬영 모드 설정
        case selectedTimerMode // 타이머 모드 선택
        case heartBeat // 세션 생존 확인
        case remoteHeartBeat // 리모트 세션 확인용
        case stopHeartBeat // heartbeat 종료
    }

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
        (videoStream, videoContinuation) = AsyncStream.makeStream(
            of: FrameReceivingEvents.self,
            bufferingPolicy: .bufferingNewest(1)
        )
        (advertisingStream, advertisingContinuation) = AsyncStream.makeStream(of: AdvertiserEvents.self)
        (modeSelectionStream, modeSelectionContinuation) = AsyncStream.makeStream(of: ModeSelectionEvents.self)
        (remoteConnectedViewStream, remoteConnectedViewContinuation) = AsyncStream.makeStream(
            of: RemoteConnectedViewEvents.self
        )
        (remoteCaptureViewStream, remoteCaptureViewContinuation) = AsyncStream.makeStream(
            of: RemoteCaptureViewEvents.self
        )
        (streamingStoreStream, streamingStoreContinuation) = AsyncStream.makeStream(of: StreamingStoreEvents.self)

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
        isBlockingInvitation = false
        advertiser.startAdvertisingPeer()
        logger.info("광고를 시작합니다.")
    }

    func stopSearching(onlyRefuse: Bool = false) {
        if onlyRefuse {
            isBlockingInvitation = true
            return
        }
        advertiser.stopAdvertisingPeer()
        logger.info("광고를 중단합니다.")
    }

    /// 세션과 연결을 해제합니다.
    func disconnect() {
        session?.disconnect()
        commandSession?.disconnect()
        session = nil
        commandSession = nil
        heartBeater.stop()
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
            if command != .heartBeat {
                logger.info("촬영 명령 전송: \(command.rawValue)")
            }
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
            advertisingContinuation.yield(.navigateToSelectModeCommand(true))
        case .navigateToSelectModeWithoutRemote:
            advertisingContinuation.yield(.navigateToSelectModeCommand(false))
        case .switchSelectModeView:
            modeSelectionContinuation.yield(.switchModeSelectionView)
        case .allPhotosStored:
            streamingStoreContinuation.yield(.onAllPhotosStored)
        case .onUpdateCaptureCount:
            streamingStoreContinuation.yield(.onUpdateCaptureCount)
        case .heartBeat:
            heartBeater.beat()
        case .captureEffect:
            streamingStoreContinuation.yield(.onCaptureEffect)
        }
    }

    private func handleRemoteDeviceCommand(_ remoteDeviceCommand: Browser.RemoteDeviceCommand) {
        switch remoteDeviceCommand {
        case .navigateToRemoteConnected:
            advertisingContinuation.yield(.navigateToRemoteConnected)
        case .navigateToRemoteCapture:
            remoteConnectedViewContinuation.yield(.navigateToRemoteCapture)
        case .navigateToRemoteComplete:
            remoteCaptureViewContinuation.yield(.navigateToRemoteComplete)
        case .navigateToHome:
            remoteConnectedViewContinuation.yield(.navigateToHome)
        case .noticeIsRemoteDevice:
            advertiserType = .remote
            heartBeater.start()
        case .heartBeat:
            heartBeater.beat()
        }
    }
}

// MARK: - Session Delegate
extension Advertiser: MCSessionDelegate {

    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        if session === self.session, state == .connected {
            heartBeater.start()
        }
        if session === self.commandSession {
            if state == .connected {
                advertisingContinuation.yield(.onConnected)
            }
        }
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        if session === self.session {
            // 스트림 세션에서 수신
            videoContinuation.yield(.streamDataReceived(data))
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
        streamingStoreContinuation.yield(.onPhotoReceived)
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
        guard isBlockingInvitation == false
                || (commandSession?.connectedPeers.contains(peerID) == true) else {
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
