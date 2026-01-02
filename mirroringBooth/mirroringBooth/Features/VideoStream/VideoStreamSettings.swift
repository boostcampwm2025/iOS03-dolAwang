//
//  VideoStreamSettings.swift
//  mirroringBooth
//
//  Created by 윤대현 on 1/2/26.
//

import Foundation

/// 비디오 스트림 설정
enum VideoStreamSettings {
    /// 해상도 설정
    enum Resolution {
        case hd      // 1280x720
        case fullHD  // 1920x1080
        
        var width: Int32 {
            switch self {
            case .hd: 1280
            case .fullHD: 1920
            }
        }
        
        var height: Int32 {
            switch self {
            case .hd: 720
            case .fullHD: 1080
            }
        }
    }
    
    /// 비트레이트 설정 (bps)
    enum BitRate {
        case low      // 2Mbps
        case medium   // 4Mbps
        case high     // 6Mbps
        
        var value: Int {
            switch self {
            case .low: 2_000_000
            case .medium: 4_000_000
            case .high: 6_000_000
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
    
    /// 기본 설정
    static let defaultResolution: Resolution = .fullHD
    static let defaultBitRate: BitRate = .high
    static let defaultFrameRate: FrameRate = .standard
}

