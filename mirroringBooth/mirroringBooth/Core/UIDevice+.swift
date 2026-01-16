//
//  UIDevice+.swift
//  mirroringBooth
//
//  Created by Liam on 1/15/26.
//

import UIKit

extension UIDevice {
    var deviceType: String {
        // build는 iOS이지만 실행 기기가 Mac인지 확인
        if ProcessInfo.processInfo.isiOSAppOnMac {
            return "Mac"
        }
        return UIDevice.current.name
    }
}
