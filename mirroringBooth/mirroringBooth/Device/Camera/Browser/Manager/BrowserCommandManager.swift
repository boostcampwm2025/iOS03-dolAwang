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
    var onRemoteModeCommand: (() -> Void)? { get }
    var onSelectedTimerModeCommand: (() -> Void)? { get }
    var mirroringHeartBeater: HeartBeater { get }
    var remoteHeartBeater: HeartBeater? { get }
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
            DispatchQueue.main.async { [weak self] in
                self?.delegate?.onRemoteModeCommand?()
                self?.delegate?.sendRemoteCommand(.navigateToRemoteCapture)
            }
        case .selectedTimerMode:
            DispatchQueue.main.async { [weak self] in
                self?.delegate?.onSelectedTimerModeCommand?()
                self?.delegate?.sendRemoteCommand(.navigateToHome)
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
