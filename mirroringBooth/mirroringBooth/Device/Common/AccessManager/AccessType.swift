//
//  AccessType.swift
//  mirroringBooth
//
//  Created by 이상유 on 2026-01-22.
//

enum AccessType {
    case camera
    case localNetwork

    var alertTitle: String {
        switch self {
        case .camera:
            return "카메라 권한 필요"
        case .localNetwork:
            return "로컬 네트워크 권한 필요"
        }
    }

    var alertMessage: String {
        switch self {
        case .camera:
            return "촬영을 위해 카메라 권한이 필요합니다.\n설정에서 권한을 허용해주세요."
        case .localNetwork:
            return "주변 기기를 검색하려면 로컬 네트워크 권한이 필요합니다.\n설정에서 권한을 허용해주세요."
        }
    }
}
