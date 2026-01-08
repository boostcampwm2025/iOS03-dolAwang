//
//  Advertiser.swift
//  mirroringBooth
//
//  Created by 이상유 on 2025-12-28.
//

import Combine
import Foundation
import MultipeerConnectivity
import OSLog

/// 서비스를 광고하고 연결 요청을 수락하여 스트림 데이터(비디오/사진)를 수신
final class Advertiser: NSObject {

    private let logger = Logger.advertiser

    private let serviceType: String
    private let peerID: MCPeerID
    private let session: MCSession
    private let commandSession: MCSession
    private let advertiser: MCNearbyServiceAdvertiser

    let myDeviceName: String

    /// 연결 콜백
    var onConnected: (() -> Void)?

    /// 연결 해제 콜백
    var onDisconnected: (() -> Void)?

    /// 수신된 스트림 데이터 콜백
    var onReceivedStreamData: ((Data) -> Void)?

    var navigateToSelectModeCommandCallBack: (() -> Void)?

    /// 사진 수신 Progress 구독 관리용 cancellables
    private var progressCancellables: [UUID: AnyCancellable] = [:]

    /// 수신된 사진 목록
    var receivedPhotos: [Photo] = []

    init(serviceType: String = "mirroringbooth") {
        self.serviceType = serviceType
        self.myDeviceName = PeerNameGenerator.makeDisplayName(isRandom: true, with: UIDevice.current.name)
        self.peerID = MCPeerID(displayName: myDeviceName)
        self.session = MCSession(
            peer: peerID,
            securityIdentity: nil,
            encryptionPreference: .required // .none은 send만 호출할 수 있다.
        )
        self.commandSession = MCSession(
            peer: peerID,
            securityIdentity: nil,
            encryptionPreference: .none
        )

        let myDeviceType: String = {
            #if os(iOS)
            if UIDevice.current.userInterfaceIdiom == .phone { return "iPhone" }
            if UIDevice.current.userInterfaceIdiom == .pad { return "iPad" }
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

        super.init()
        setup()
    }

    private func setup() {
        session.delegate = self
        commandSession.delegate = self
        advertiser.delegate = self
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
        session.disconnect()
        commandSession.disconnect()
        logger.info("연결 해제: \(self.peerID.displayName)")
    }

    private func updatePhotoState(
        photoID: UUID,
        state: PhotoReceiveState
    ) {
        guard let index = receivedPhotos.firstIndex(where: { $0.id == photoID }) else { return }
        receivedPhotos[index].state = state
    }

    private func executeCommand(data: Data) {
        guard let command = String(data: data, encoding: .utf8) else { return }
        if let type = Browser.MirroringDeviceCommand(rawValue: command) {
            switch type {
            case .navigateToSelectMode:
                guard let navigateToSelectModeCommandCallBack else { return }
                navigateToSelectModeCommandCallBack()
            }
        }
    }
}

// MARK: - Session Delegate
extension Advertiser: MCSessionDelegate {

    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
        case .connected:
            onConnected?()
        case .notConnected:
            onDisconnected?()
        default:
            break
        }
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        if session === self.session {
            // 수신된 스트림 데이터를 라우터로 전달
            onReceivedStreamData?(data)
        } else if session === commandSession {
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
        guard let photoID = UUID(
            uuidString: resourceName.replacingOccurrences(of: ".jpg", with: "")
        ) else { return }

        DispatchQueue.main.async {
            self.receivedPhotos.insert(
                Photo(id: photoID, state: .receiving(progress: 0)),
                at: 0
            )
        }

        let cancellable = progress.publisher(for: \.fractionCompleted)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] fraction in
                self?.updatePhotoState(
                    photoID: photoID,
                    state: .receiving(progress: fraction)
                )

                if fraction >= 1.0 {
                    self?.progressCancellables[photoID] = nil
                }
            }

        progressCancellables[photoID] = cancellable
    }

    /// 파일 전송이 완료되었거나 실패했음을 알립니다.
    func session(
        _ session: MCSession,
        didFinishReceivingResourceWithName resourceName: String,
        fromPeer peerID: MCPeerID,
        at localURL: URL?,
        withError error: Error?
    ) {
        guard let photoID = UUID(
            uuidString: resourceName.replacingOccurrences(of: ".jpg", with: "")
        ) else { return }

        progressCancellables[photoID] = nil

        if let error {
            logger.warning("사진 수신 실패: \(error.localizedDescription)")
            updatePhotoState(photoID: photoID, state: .failed)
            return
        }

        guard let localURL,
              let data = try? Data(contentsOf: localURL) // TODO: 데이터 변환 방식 수정
        else {
            updatePhotoState(photoID: photoID, state: .failed)
            return
        }

        updatePhotoState(photoID: photoID, state: .completed(data))
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
            invitationHandler(false, nil)
            return
        }
        logger.info("초대 수신: \(peerID.displayName)(타입: \(type))")
        // 임시적으로 수신된 초대가 자동으로 수락되도록 작성했습니다.
        if type == "streaming" {
            invitationHandler(true, session)
        } else if type == "command" {
            invitationHandler(true, commandSession)
        }
    }
}
