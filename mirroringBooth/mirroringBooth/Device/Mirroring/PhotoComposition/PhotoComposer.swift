//
//  PhotoComposer.swift
//  mirroringBooth
//
//  Created by 이상유 on 2026-01-14.
//

import SwiftUI

struct PhotoComposer {
    static func render(with information: PhotoInformation) async -> UIImage? {
        let photoImages = await PhotoImageLoader.loadImages(from: information.photos)
        //  CI의 Xcode 16.4는 Default Actor Isolation을 `nonisolated`이 기본 설정
        //  Xcode 버전이 26.* 이라면 Default Actor Isolation을 `MainActor`이 기본 설정
        //  CI와 로컬 환경의 버전이 달라 임시로 CI 환경에 맞는 형태로 코드를 작성하였음
        return await renderPreview(with: information, photoImages: photoImages)
    }

    @MainActor
    private static func renderPreview(with information: PhotoInformation, photoImages: [UIImage?]) -> UIImage? {
        // 출력 이미지 크기 결정 (예: 1080 x 1440 또는 레이아웃 비율에 맞춤)
        let targetWidth: CGFloat = 1080
        let targetHeight: CGFloat = targetWidth / information.layout.previewAspect
        let targetSize = CGSize(width: targetWidth, height: targetHeight)

        let preview = PhotoFramePreview(
            information: information,
            photoImages: photoImages
        )
        .frame(width: targetSize.width, height: targetSize.height)

        let renderer = ImageRenderer(content: preview)

        // GPU 텍스처 한계(약 8192px)를 초과하지 않도록 scale 조정
        let maxDimension: CGFloat = 8192
        let maxScale = min(maxDimension / targetWidth, maxDimension / targetHeight)
        renderer.scale = min(UIScreen.main.scale, maxScale)

        guard let metalImage = renderer.uiImage else { return nil }

        // 알파 채널 제거
        let format = UIGraphicsImageRendererFormat()
        format.opaque = true
        format.scale = metalImage.scale

        let imageRenderer = UIGraphicsImageRenderer(size: metalImage.size, format: format)
        return imageRenderer.image { _ in
            metalImage.draw(at: .zero)
        }
    }
}
