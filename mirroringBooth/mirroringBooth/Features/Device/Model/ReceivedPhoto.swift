//
//  ReceivedPhoto.swift
//  mirroringBooth
//
//  Created by 윤대현 on 1/3/26.
//

import Foundation

// View 표시용 모델
struct ReceivedPhoto: Identifiable {
    let id: UUID
    var state: PhotoReceiveState
}
