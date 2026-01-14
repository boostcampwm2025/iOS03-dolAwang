//
//  FrameAsset.swift
//  mirroringBooth
//
//  Created by 최윤진 on 1/14/26.
//

import SwiftUI

enum FrameAsset: String, CaseIterable {
    case black
    case white
    case crowded
    case orange
    case skyblue

    var image: Image {
        switch self {
        case .black:
            return Image("black")
        case .white:
            return Image("white")
        case .crowded:
            return Image("crowded")
        case .orange:
            return Image("orange")
        case .skyblue:
            return Image("skyblue")
        }
    }
}
