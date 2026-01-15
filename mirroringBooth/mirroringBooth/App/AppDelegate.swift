//
//  AppDelegate.swift
//  mirroringBooth
//
//  Created by 최윤진 on 1/15/26.
//

import UIKit

final class AppDelegate: NSObject, UIApplicationDelegate {
    static var supportedOrientations: UIInterfaceOrientationMask = .all

    override init() {
        if UIDevice.current.userInterfaceIdiom == .phone {
            Self.lockOrientation()
        }
        super.init()
    }

    func application(
        _ application: UIApplication,
        supportedInterfaceOrientationsFor window: UIWindow?
    ) -> UIInterfaceOrientationMask {
        return AppDelegate.supportedOrientations
    }

    static func lockOrientation() {
        if UIDevice.current.userInterfaceIdiom != .phone { return }
        self.supportedOrientations = .portrait

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            return
        }

        if #available(iOS 16.0, *) {
            let geometryPreferences: UIWindowScene.GeometryPreferences.iOS = .init(interfaceOrientations: .portrait)
            windowScene.requestGeometryUpdate(geometryPreferences)
        }
    }

    static func unlockOrientation() {
        self.supportedOrientations = .all

    }
}
