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
        case low      // 1Mbps
        case medium   // 2Mbps
        case high     // 3Mbps
        
        var value: Int {
            switch self {
            case .low: 1_000_000
            case .medium: 2_000_000
            case .high: 3_000_000
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
    static let defaultResolution: Resolution = .hd
    static let defaultBitRate: BitRate = .medium
    static let defaultFrameRate: FrameRate = .standard
}

