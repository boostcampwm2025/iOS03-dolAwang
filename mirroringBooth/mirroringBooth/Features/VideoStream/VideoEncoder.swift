//
//  VideoEncoder.swift
//  mirroringBooth
//
//  Created by 윤대현 on 1/2/26.
//

import CoreMedia
import Foundation

/// 비디오 인코딩 프로토콜
/// H.264, H.265 등 다양한 코덱 구현체가 채택하도록 의도합니다.
protocol VideoEncoder {
    /// 인코딩 세션을 시작합니다.
    func start()
    
    /// 인코딩 세션을 중지합니다.
    func stop()
    
    /// 샘플 버퍼를 인코딩하여 데이터로 변환합니다.
    /// - Parameter sampleBuffer: 인코딩할 CMSampleBuffer
    /// - Returns: 인코딩된 데이터 (H.264 NAL units 등)
    func encode(_ sampleBuffer: CMSampleBuffer) -> Data?
}

