//
//  AccessManager.swift
//  mirroringBooth
//
//  Created by 이상유 on 2026-01-22.
//

import AVFoundation.AVCaptureDevice
import Network
import UIKit

@Observable
final class AccessManager {
    var showCameraSettingAlert: Bool = false
    var showLocalNetworkSettingAlert: Bool = false

    var accessTitle: String {
        if showCameraSettingAlert {
            return "카메라 권한 필요"
        } else if showLocalNetworkSettingAlert {
            return "로컬 네트워크 권한 필요"
        }
        return ""
    }

    var accessDescription: String {
        if showCameraSettingAlert {
            return "촬영을 위해 카메라 권한이 필요합니다.\n설정에서 권한을 허용해주세요."
        } else if showLocalNetworkSettingAlert {
            return "주변 기기를 검색하려면 로컬 네트워크 권한이 필요합니다.\n설정에서 권한을 허용해주세요."
        }
        return ""
    }

    private var localNetworkBrowser: NWBrowser?
    private var successTimerItem: DispatchWorkItem?

    /// 설정 앱으로 이동
    func openSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(settingsURL)
    }

    /// 카메라 권한 확인 및 요청
    func requestCameraAccess(onGranted: @escaping () -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            onGranted()

        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    onGranted()
                }
            }

        case .denied, .restricted:
            showCameraSettingAlert = true

        @unknown default:
            break
        }
    }

    /// 로컬 네트워크 권한 확인 및 요청
    func requestLocalNetworkAccess(onGranted: @escaping () -> Void) {
        // 1. 초기화
        stopCheckingLocalNetwork()
        let browser = NWBrowser(for: .bonjour(type: "_mirroringbooth._tcp", domain: nil), using: .tcp)

        // 2. [성공 확정 타이머]
        // 지정된 시간 동안 거절 에러가 발생하지 않으면 성공으로 간주
        let timerItem = DispatchWorkItem { [weak self] in
            print("결과: 거절 에러 없음 -> 권한 허용으로 간주")
            self?.stopCheckingLocalNetwork()
            onGranted()
        }
        self.successTimerItem = timerItem

        browser.stateUpdateHandler = { [weak self] state in
            guard let self = self else { return }

            if isPolicyDenied(state) {
                // [확실한 실패] 사용자가 권한을 명시적으로 거부함
                print("결과: 권한 거부됨 (Policy Denied)")
                self.successTimerItem?.cancel()
                self.stopCheckingLocalNetwork()
                self.showLocalNetworkSettingAlert = true
                return
            }
        }

        self.localNetworkBrowser = browser
        browser.start(queue: .main)

        // 0.5초 대기
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: timerItem)
    }

}

// MARK: - Local Network private methods

private extension AccessManager {
    func stopCheckingLocalNetwork() {
        localNetworkBrowser?.cancel()
        localNetworkBrowser = nil
        successTimerItem?.cancel()
        successTimerItem = nil
    }

    func isPolicyDenied(_ state: NWBrowser.State) -> Bool {
        if case .waiting(let error) = state,
           case .dns(DNSServiceErrorType(kDNSServiceErr_PolicyDenied)) = error {
            return true
        }
        return false
    }
}
