//
//  VideoPlayerViewModel.swift
//  mirroringBooth
//
//  Created by 이상유 on 2025-12-27.
//

import Foundation
import SwiftUI
import CoreImage
import Combine

/// VideoPlayerView의 ViewModel
/// 디코딩된 프레임을 UI에 전달하는 역할
@MainActor
final class VideoPlayerViewModel: ObservableObject {

    /// 현재 화면에 표시할 프레임 이미지
    @Published var currentFrame: CGImage?

    private let decoder: VideoDecoder
    /// CoreImage 컨텍스트 - CVPixelBuffer를 CGImage로 변환
    private let ciContext = CIContext()
    
    init(decoder: VideoDecoder) {
        self.decoder = decoder

        // 디코더로부터 프레임을 받아 UI 업데이트
        decoder.onDecodedFrame = { [weak self] pixelBuffer in
            self?.updateFrame(pixelBuffer)
        }
    }
    
    /// CVPixelBuffer를 CGImage로 변환하여 UI 업데이트
    /// - Parameter pixelBuffer: 디코딩된 프레임 (YUV420 포맷)
    private func updateFrame(_ pixelBuffer: CVPixelBuffer) {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        
        guard let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent) else {
            return
        }
        
        // UI 업데이트는 메인 스레드에서 수행
        DispatchQueue.main.async { [weak self] in
            self?.currentFrame = cgImage
        }
    }
    
}
