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
    var state: ConnectionState = .notConnected
    let type: DeviceType

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: NearbyDevice, rhs: NearbyDevice) -> Bool {
        lhs.id == rhs.id
    }
}
