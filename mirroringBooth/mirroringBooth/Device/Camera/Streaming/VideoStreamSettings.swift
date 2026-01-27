//
//  VideoStreamSettings.swift
//  mirroringBooth
//
//  Created by 윤대현 on 1/2/26.
//

import Foundation

/// 비디오 스트림 설정
enum VideoStreamSettings {

    /// 기본 설정
    static let defaultResolution: Resolution = .hd1080p
    static let defaultBitRate: BitRate = .high
    static let defaultFrameRate: FrameRate = .high

    /// 해상도 설정
    enum Resolution {
        case hd720p           // 1280x720 (가로)
        case hd1080p          // 1920x1080 (가로)
        case hd4k             // 3840x2160 (가로)
        case portraitHD1080p  // 1080x1920 (세로)
        case photo            // 1440x1080 (세로)

        var width: Int32 {
            switch self {
            case .hd720p: 1280
            case .hd1080p: 1920
            case .hd4k: 3840
            case .portraitHD1080p: 1080
            case .photo: 1440
            }
        }

        var height: Int32 {
            switch self {
            case .hd720p: 720
            case .hd1080p: 1080
            case .hd4k: 2160
            case .portraitHD1080p, .photo: 1920
            }
        }
    }

    /// 비트레이트 설정 (bps)
    enum BitRate {
        case low      // 2Mbps
        case medium   // 4Mbps
        case high     // 6Mbps
        case hd4k // 30Mbps

        var value: Int {
            switch self {
            case .low: 2_000_000
            case .medium: 4_000_000
            case .high: 6_000_000
            case .hd4k: 35_000_000
            }
        }
    }

    /// 프레임 레이트 설정
    enum FrameRate {
        case low      // 24fps
        case standard // 30fps
        case high     // 60fps

        var value: Int {
            switch self {
            case .low: 24
            case .standard: 30
            case .high: 60
            }
        }
    }

}
