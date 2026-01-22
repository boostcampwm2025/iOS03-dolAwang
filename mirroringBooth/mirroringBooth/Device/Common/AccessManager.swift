//
//  AccessManager.swift
//  mirroringBooth
//
//  Created by 이상유 on 2026-01-22.
//

import AVFoundation.AVCaptureDevice
import UIKit

final class AccessManager {
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
            openSettings()

        @unknown default:
            break
        }
    }

    private func openSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(settingsURL)
    }
}
