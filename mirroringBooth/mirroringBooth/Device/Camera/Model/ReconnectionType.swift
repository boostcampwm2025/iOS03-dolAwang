//
//  ReconnectionType.swift
//  mirroringBooth
//
//  Created by 윤대현 on 2026-01-13.
//

enum ReconnectionType {
    case mirroringOnly // 미러링 기기만 재연결
    case remoteOnly    // 리모트 기기만 재연결
    case both          // 둘 다 재연결 (순차적으로)

    var title: String {
        switch self {
        case .mirroringOnly:
            "미러링 기기 재연결"
        case .remoteOnly:
            "리모트 기기 재연결"
        case .both:
            "모든 기기 재연결"
        }
    }

    var description: String {
        switch self {
        case .mirroringOnly:
            "미러링 기기와의 연결이 끊어졌습니다.\n다시 연결해주세요."
        case .remoteOnly:
            "리모트 기기와의 연결이 끊어졌습니다.\n다시 연결해주세요."
        case .both:
            "미러링과 리모트 기기와의 연결이 끊어졌습니다.\n다시 연결해주세요."
        }
    }

    var icon: String {
        switch self {
        case .mirroringOnly:
            "display"
        case .remoteOnly:
            "target"
        case .both:
            "exclamationmark.triangle.fill"
        }
    }

    // 재연결할 기기 타입 목록
    var targetTypes: [DeviceUseType] {
        switch self {
        case .mirroringOnly:
            [.mirroring]
        case .remoteOnly:
            [.remote]
        case .both:
            [.mirroring, .remote]
        }
    }
}
