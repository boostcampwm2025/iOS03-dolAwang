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
    private let photoCacheManager: PhotoCacheManager
    private let heartBeater: HeartBeater
    var advertiserType: DeviceUseType = .mirroring // heartbeat 메시지 종류 구분을 위해 추가
    let myDeviceName: String

    let connectionManager: AdvertisingManager
    let streamManager = StreamManager()
    private let commandManager: AdvertiserCommandManager

    var videoStream: AsyncStream<FrameReceivingEvents> { streamManager.videoStream }
    var advertisingStream: AsyncStream<AdvertiserEvents> { streamManager.advertisingStream }
    var modeSelectionStream: AsyncStream<ModeSelectionEvents> { streamManager.modeSelectionStream }
    var remoteConnectedViewStream: AsyncStream<RemoteConnectedViewEvents> { streamManager.remoteConnectedViewStream }
    var remoteCaptureViewStream: AsyncStream<RemoteCaptureViewEvents> { streamManager.remoteCaptureViewStream }
    var streamingStoreStream: AsyncStream<StreamingStoreEvents> { streamManager.streamingStoreStream }
    var rootStream: AsyncStream<RootEvents> { streamManager.rootStream }

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

        self.connectionManager = AdvertisingManager(
            serviceType: serviceType,
            peerID: peerID,
            discoveryInfo: ["deviceType": myDeviceType]
        )
        self.photoCacheManager = photoCacheManager
        self.heartBeater = HeartBeater(repeatInterval: 1.0, timeout: 2.5)

        self.commandManager = AdvertiserCommandManager(streamManager: streamManager, heartBeater: heartBeater)
        super.init()

        connectionManager.delegate = self
        connectionManager.connectedPeersCheck = { [weak self] peerID in
            self?.session?.connectedPeers.contains(peerID) == true
        }
        heartBeater.delegate = self
    }

    func setupCacheManager() {
        Task {
            await photoCacheManager.startNewSession()
        }
    }

    func startSearching() {
        connectionManager.startAdvertising()
    }

    func stopSearching(onlyRefuse: Bool = false) {
        connectionManager.stopAdvertising(onlyRefuse: onlyRefuse)
    }

    /// 세션과 연결을 해제합니다.
    func disconnect() {
        session?.disconnect()
        session = nil
        heartBeater.stop()
        logger.info("연결 해제: \(self.peerID.displayName)")
    }

    func stopHeartBeating() {
        sendCommand(.stopHeartBeat)
        heartBeater.stop()
    }

    /// 연결된 카메라 기기(iPhone)에게 명령을 전송합니다.
    func sendCommand(_ command: CameraDeviceCommand) {
        commandManager.send(command, session: session)
    }
}

// MARK: - Session Delegate
extension Advertiser: MCSessionDelegate {

    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        if session === self.session, state == .connected {
            heartBeater.start()
            streamManager.yieldAdvertising(.onConnected)
        }
        if state == .connecting {
            connectionManager.stopIfAdvertising()
        } else if state == .notConnected || state == .connected {
            connectionManager.startIfAdvertising()
        }
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        guard let firstByte = data.first else { return }
        let payload = data.dropFirst()

        if session === self.session {
            if firstByte == MultipeerHeader.command.rawValue {
                commandManager.execute(data: payload, advertiserType: &advertiserType)
            } else if firstByte == MultipeerHeader.streaming.rawValue {
                streamManager.yieldVideo(payload)
            }
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
        streamManager.yieldStreamingStore(.onPhotoReceived)
    }
}

// MARK: - ConnectionManager Delegate
extension Advertiser: ConnectionManagerDelegate {
    func connectionManager(_ manager: AdvertisingManager, didCreateSession session: MCSession) {
        self.session = session
        session.delegate = self
    }
}
