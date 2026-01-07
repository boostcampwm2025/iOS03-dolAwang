//
//  Pose.swift
//  mirroringBooth
//
//  Created by 윤대현 on 1/7/26.
//

import Foundation

enum Pose: String, CaseIterable, Identifiable {
    case none = "None"
    case heart = "볼 하트"
    case vpose = "브이"
    case flower = "꽃받침"

    var id: String { rawValue }

    var imageName: String? {
        switch self {
        case .none: return nil
        case .heart: return "pose_heart"
        case .vpose: return "pose_v"
        case .flower: return "pose_flower"
        }
    }
}
