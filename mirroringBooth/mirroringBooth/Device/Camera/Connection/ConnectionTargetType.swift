//
//  ConnectionTargetType.swift
//  mirroringBooth
//
//  Created by 이상유 on 2026-01-07.
//

enum ConnectionTargetType {
    case mirroring
    case remote

    var searchTitle: String {
        switch self {
        case .mirroring:
            "미러링 기기 찾는 중"
        case .remote:
            "리모트 기기 찾는 중"
        }
    }

    var searchDescription: String {
        switch self {
        case .mirroring:
            "화면을 공유할 기기를 선택해주세요."
        case .remote:
            "원격 촬영을 위한 기기를 선택해주세요."
        }
    }
}
