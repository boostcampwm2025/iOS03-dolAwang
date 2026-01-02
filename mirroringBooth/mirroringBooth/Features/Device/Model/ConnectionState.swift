//
//  ConnectionState.swift
//  mirroringBooth
//
//  Created by 윤대현 on 12/29/25.
//

import Foundation

/// 기기 연결 상태
enum ConnectionState: String {
    case notConnected = "연결 안됨"
    case connecting = "연결 중"
    case connected = "연결됨"
}

