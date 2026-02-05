//
//  BrowserCommandManager.swift
//  mirroringBooth
//
//  Created by 윤대현 on 2026-02-04.
//

import Foundation

protocol BrowserCommandDelegate: AnyObject {
    func capturePhoto()
    func sendRemoteCommand(_ command: RemoteDeviceCommand)
    func disconnect(useType: DeviceUseType, onPurpose: Bool)
    var onRemoteModeCommand: (() -> Void)? { get }
    var onSelectedTimerModeCommand: (() -> Void)? { get }
    var mirroringHeartBeater: HeartBeater { get }
    var remoteHeartBeater: HeartBeater? { get }
    var isTimerModeSelected: Bool { get set }
}

/// 명령 수신 및 실행을 담당하는 매니저
final class BrowserCommandManager {

    private let streamManager: BrowserStreamManager
    weak var delegate: BrowserCommandDelegate?

    init(streamManager: BrowserStreamManager) {
        self.streamManager = streamManager
    }

    func execute(data: Data) {
        guard let command = String(data: data, encoding: .utf8) else { return }
        guard let type = Advertiser.CameraDeviceCommand(rawValue: command) else { return }

        switch type {
        case .capturePhoto:
            DispatchQueue.main.async { [weak self] in
                self?.delegate?.capturePhoto()
            }
        case .startTransfer:
            DispatchQueue.main.async { [weak self] in
                self?.streamManager.yieldCameraStreamEvent(.startTransfer)
                self?.delegate?.sendRemoteCommand(.navigateToRemoteComplete)
            }
        case .setRemoteMode:
            delegate?.isTimerModeSelected = false
            DispatchQueue.main.async { [weak self] in
                self?.delegate?.onRemoteModeCommand?()
                self?.delegate?.sendRemoteCommand(.navigateToRemoteCapture)
            }
        case .selectedTimerMode:
            // 워치 disconnect 무시를 위해 동기적으로 먼저 플래그 설정
            delegate?.isTimerModeSelected = true
            DispatchQueue.main.async { [weak self] in
                self?.delegate?.onSelectedTimerModeCommand?()
                self?.delegate?.sendRemoteCommand(.navigateToHome)
                self?.delegate?.sendRemoteCommand(.stopHeartBeat)
                self?.delegate?.disconnect(useType: .remote, onPurpose: true)
            }
        case .heartBeat:
            delegate?.mirroringHeartBeater.beat()
        case .remoteHeartBeat:
            delegate?.remoteHeartBeater?.beat()
        case .stopHeartBeat:
            DispatchQueue.main.async { [weak self] in
                self?.delegate?.sendRemoteCommand(.stopHeartBeat)
            }
            delegate?.mirroringHeartBeater.stop()
            delegate?.remoteHeartBeater?.stop()
        }
    }
}
