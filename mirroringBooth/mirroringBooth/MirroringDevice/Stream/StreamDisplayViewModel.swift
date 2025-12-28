//
//  StreamDisplayViewModel.swift
//  mirroringBooth
//
//  Created by 이상유 on 2025-12-27.
//

import Foundation
import SwiftUI
import CoreImage
import Combine

/// StreamDisplayView의 ViewModel
/// 디코딩된 프레임과 촬영된 사진을 UI에 전달하는 역할
@MainActor
final class StreamDisplayViewModel: ObservableObject {

    /// 현재 화면에 표시할 프레임 이미지
    @Published var currentFrame: CGImage?

    /// 촬영된 고화질 사진
    @Published var capturedPhoto: UIImage?

    /// CoreImage 컨텍스트 - CVPixelBuffer를 CGImage로 변환
    private let ciContext = CIContext()

    /// CVPixelBuffer를 CGImage로 변환하여 UI 업데이트
    /// - Parameter pixelBuffer: 디코딩된 프레임 (YUV420 포맷)
    func handleDecodedFrame(_ pixelBuffer: CVPixelBuffer) {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)

        guard let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent) else {
            return
        }

        // UI 업데이트는 메인 스레드에서 수행
        DispatchQueue.main.async { [weak self] in
            self?.currentFrame = cgImage
        }
    }

    /// 수신된 사진 데이터를 UIImage로 변환하여 저장
    /// - Parameter data: JPEG 이미지 데이터
    func handleReceivedPhoto(_ data: Data) {
        guard let image = UIImage(data: data) else {
            print("Failed to create UIImage from photo data")
            return
        }

        DispatchQueue.main.async { [weak self] in
            self?.capturedPhoto = image
        }
    }

}
