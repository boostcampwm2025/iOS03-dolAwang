//
//  NearbyDevice.swift
//  mirroringBooth
//
//  Created by 윤대현 on 12/29/25.
//

import Foundation

/// View 표시용 모델
struct NearbyDevice: Hashable, Identifiable {
    let id: String
    let name: String
    var state: ConnectionState = .notConnected
}

