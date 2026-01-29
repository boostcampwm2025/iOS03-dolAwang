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
    case burgundy = "Burgundy"
    case darkGray = "Dark Gray"
    case deepGreen = "Deep Green"
    case navy = "Navy Blue"

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
        case .burgundy:
            return UIImage(named: "burgundy")
        case .darkGray:
            return UIImage(named: "darkGray")
        case .deepGreen:
            return UIImage(named: "deepGreen")
        case .navy:
            return UIImage(named: "navy")
        }
    }

    var textColor: Color {
        switch self {
        case .black, .burgundy, .darkGray, .deepGreen, .navy:
            return .white
        default:
            return .black
        }
    }

    var dateBackgroundName: String? {
        switch self {
        case .crowded, .orange, .skyblue:
            return "orangeSigns"
        default:
            return nil
        }
    }
}
