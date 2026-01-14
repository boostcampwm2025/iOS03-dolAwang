//
//  PhotoComposer.swift
//  mirroringBooth
//
//  Created by 이상유 on 2026-01-14.
//

import SwiftUI

struct PhotoComposer {
    static func render(
        layout: PhotoFrameLayout,
        frame: UIImage,
        photos: [UIImage]
    ) -> UIImage? {
        let preview = PhotoFramePreview(
            layout: layout,
            frame: frame,
            photos: photos
        )
        let renderer = ImageRenderer(content: preview)
        renderer.scale = UIScreen.main.scale // 고해상도
        return renderer.uiImage
    }
}
