//
//  PhotoReceiveState.swift
//  mirroringBooth
//
//  Created by 윤대현 on 1/3/26.
//

import Foundation

// 사진 전송 상태
enum PhotoReceiveState {
    case receiving(progress: Double)
    case completed(Data)
    case failed
}
