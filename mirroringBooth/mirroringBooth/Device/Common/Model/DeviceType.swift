//
//  DeviceType.swift
//  mirroringBooth
//
//  Created by 이상유 on 2026-01-07.
//

enum DeviceType: String {
    case iPhone
    case iPad
    case mac
    case unknown

    var icon: String {
        switch self {
        case .iPhone:
            return "iphone"
        case .iPad:
            return "ipad"
        case .mac:
            return "macbook"
        case .unknown:
            return "questionmark.circle"
        }
    }

    static func from(string: String) -> DeviceType? {
        switch string.lowercased() {
        case "iphone":
            return .iPhone
        case "ipad":
            return .iPad
        case "mac":
            return .mac
        default:
            return nil
        }
    }
}
