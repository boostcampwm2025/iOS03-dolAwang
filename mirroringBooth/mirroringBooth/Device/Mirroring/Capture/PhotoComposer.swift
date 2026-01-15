//
//  PhotoComposer.swift
//  mirroringBooth
//
//  Created by 이상유 on 2026-01-14.
//

import SwiftUI

struct PhotoComposer {
    @MainActor
    static func render(with information: PhotoInformation) -> UIImage? {
        // 출력 이미지 크기 결정 (예: 1080 x 1440 또는 레이아웃 비율에 맞춤)
        let targetWidth: CGFloat = 1080
        let targetHeight: CGFloat = targetWidth / information.layout.previewAspect
        let targetSize = CGSize(width: targetWidth, height: targetHeight)

        let preview = PhotoFramePreview(information: information)
        .frame(width: targetSize.width, height: targetSize.height)

        let renderer = ImageRenderer(content: preview)
        renderer.scale = UIScreen.main.scale // 고해상도
        return renderer.uiImage
    }
}
