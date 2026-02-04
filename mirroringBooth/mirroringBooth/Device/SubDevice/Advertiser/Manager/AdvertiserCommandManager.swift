//
//  CommandManager.swift
//  mirroringBooth
//
//  Created by Liam on 2/3/26.
//

import Foundation
import MultipeerConnectivity
import OSLog

/// 명령 송수신 및 처리를 담당하는 매니저
final class AdvertiserCommandManager {
    private weak var streamManager: StreamManager?
    private weak var heartBeater: HeartBeater?

    init(streamManager: StreamManager, heartBeater: HeartBeater) {
        self.streamManager = streamManager
        self.heartBeater = heartBeater
    }

    // MARK: - Command Execution
    func execute(data: Data, advertiserType: inout DeviceUseType) {
        guard let commandString = String(data: data, encoding: .utf8) else { return }

        if let mirroringDeviceCommand = MirroringDeviceCommand(rawValue: commandString) {
            handleMirroringDeviceCommand(mirroringDeviceCommand)
            return
        }

        if let remoteDeviceCommand = RemoteDeviceCommand(rawValue: commandString) {
            handleRemoteDeviceCommand(remoteDeviceCommand, advertiserType: &advertiserType)
            return
        }
    }

    private func handleMirroringDeviceCommand(_ command: MirroringDeviceCommand) {
        switch command {
        case .navigateToSelectModeWithRemote:
            streamManager?.yieldAdvertising(.navigateToSelectModeCommand(true))
        case .navigateToSelectModeWithoutRemote:
            streamManager?.yieldAdvertising(.navigateToSelectModeCommand(false))
        case .switchSelectModeView:
            streamManager?.yieldModeSelection(.switchModeSelectionView)
        case .onStoreAllPhotos:
            streamManager?.yieldStreamingStore(.onStoreAllPhotos)
        case .onUpdateCaptureCount:
            streamManager?.yieldStreamingStore(.onUpdateCaptureCount)
        case .heartBeat:
            heartBeater?.beat()
        case .captureEffect:
            streamManager?.yieldStreamingStore(.onCaptureEffect)
        }
    }

    private func handleRemoteDeviceCommand(
        _ command: RemoteDeviceCommand,
        advertiserType: inout DeviceUseType
    ) {
        switch command {
        case .navigateToRemoteConnected:
            streamManager?.yieldAdvertising(.navigateToRemoteConnected)
        case .navigateToRemoteCapture:
            streamManager?.yieldRemoteConnectedView(.navigateToRemoteCapture)
        case .navigateToRemoteComplete:
            streamManager?.yieldRemoteCaptureView(.navigateToRemoteComplete)
        case .navigateToHome:
            streamManager?.yieldRemoteConnectedView(.navigateToHome)
        case .noticeIsRemoteDevice:
            advertiserType = .remote
            heartBeater?.start()
        case .heartBeat:
            heartBeater?.beat()
        }
    }

    // MARK: - Command Sending
    func send(_ command: Advertiser.CameraDeviceCommand, session: MCSession?) {
        guard let session, let commandData = command.rawValue.data(using: .utf8) else { return }
        let connectedPeers = session.connectedPeers
        guard !connectedPeers.isEmpty else {
            Logger.advertiserCommandmanager.warning("명령 전송 실패: commandSession에 연결된 피어가 없습니다")
            return
        }

        do {
            try session.send(commandData, toPeers: connectedPeers, with: .reliable)
            if command != .heartBeat {
                Logger.advertiserCommandmanager.info("촬영 명령 전송: \(command.rawValue)")
            }
        } catch {
            Logger.advertiserCommandmanager.warning("명령 전송 실패: \(error.localizedDescription)")
        }
    }
}
