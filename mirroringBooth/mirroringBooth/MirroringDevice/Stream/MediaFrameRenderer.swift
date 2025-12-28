//
//  MediaFrameRenderer.swift
//  mirroringBooth
//
//  Created by 이상유 on 2025-12-27.
//

import Foundation
import SwiftUI
import CoreImage
import Combine

/// 디코딩된 비디오 프레임을 UI에 렌더링 가능한 형태로 변환
@MainActor
final class MediaFrameRenderer: ObservableObject {

    /// 현재 화면에 표시할 프레임 이미지
    @Published var currentFrame: CGImage?

    /// CoreImage 컨텍스트 - CVPixelBuffer를 CGImage로 변환
    private let ciContext = CIContext()

    /// CVPixelBuffer를 CGImage로 변환하여 UI 업데이트
    /// - Parameter pixelBuffer: 디코딩된 프레임 (YUV420 포맷)
    func renderDecodedFrame(_ pixelBuffer: CVPixelBuffer) {
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
