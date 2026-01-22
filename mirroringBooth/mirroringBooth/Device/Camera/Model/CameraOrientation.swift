//
//  CameraOrientation.swift
//  mirroringBooth
//
//  Created by 최윤진 on 1/22/26.
//

import Foundation

enum CameraOrientation: UInt8 {
    case portrait
    case landscapeLeft
    case landscapeRight

    var rotationAngle: CGFloat {
        switch self {
        case .portrait:
            return 90
        case .landscapeLeft:
            return 180
        case .landscapeRight:
            return 0
        }
    }
}
