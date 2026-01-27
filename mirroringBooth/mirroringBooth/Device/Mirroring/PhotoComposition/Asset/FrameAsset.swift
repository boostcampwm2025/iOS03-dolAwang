//
//  FrameAsset.swift
//  mirroringBooth
//
//  Created by 최윤진 on 1/14/26.
//

import SwiftUI

enum FrameAsset: String, Identifiable, CaseIterable {
    var id: Self { self }

    case black = "Basic Black"
    case white = "Basic White"
    case crowded = "Crowded persimmon"
    case orange = "Persimmons (Orange)"
    case skyblue = "Persimmons (Sky Blue)"

    var image: UIImage? {
        switch self {
        case .black:
            return UIImage(named: "black")
        case .white:
            return UIImage(named: "white")
        case .crowded:
            return UIImage(named: "crowded")
        case .orange:
            return UIImage(named: "orange")
        case .skyblue:
            return UIImage(named: "skyblue")
        }
    }

    var textColor: Color {
        switch self {
        case .black:
            return .white
        default:
            return .black
        }
    }

    var dateBackgroundName: String? {
        switch self {
        case .black, .white:
            return nil
        default:
            return "orangeSigns"
        }
    }
}
