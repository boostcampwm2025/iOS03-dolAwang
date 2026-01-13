//
//  PhotoFramePreview.swift
//  mirroringBooth
//
//  Created by 이상유 on 2026-01-14.
//

import SwiftUI
import UIKit

struct PhotoFramePreview: View {
    let layout: PhotoFrameLayout
    let frame: UIImage
    let photos: [UIImage]

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size

            Canvas { context, _ in
                let canvas = CGRect(origin: .zero, size: size)

                // 1. 프레임 (배경)
                context.drawLayer { layer in
                    let frameTarget = aspectFillRect(for: frame.size, into: canvas)
                    layer.draw(Image(uiImage: frame), in: frameTarget)
                }

                // 2. 사진 슬롯들
                let slots = layout.frameRects().map { $0.denormalized(in: size) }
                for (index, slot) in slots.enumerated() {
                    guard index < photos.count else { continue }
                    let photo = photos[index]

                    context.drawLayer { layer in
                        layer.clip(to: Path(roundedRect: slot, cornerRadius: 12))
                        let target = aspectFillRect(for: photo.size, into: slot)
                        layer.draw(Image(uiImage: photo), in: target)
                    }
                }
            }
        }
        .aspectRatio(layout.previewAspect, contentMode: .fit)
    }

    /// Cliping 될 때 크기에 맞게 잘 잘리도록 전처리
    private func aspectFillRect(for size: CGSize, into slot: CGRect) -> CGRect {
        guard size.width > 0, size.height > 0 else { return slot }

        let imageAspect = size.width / size.height
        let slotAspect = slot.width / slot.height

        if imageAspect > slotAspect {
            // 이미지가 더 가로로 김
            let height = slot.height // 높이는 슬롯에 딱 맞춤
            let width = height * imageAspect // 그 높이에 맞는 사진 너비로 확대
            let posX = slot.midX - width / 2 // 가운데 정렬(좌우 잘림이 대칭)
            return CGRect(x: posX, y: slot.minY, width: width, height: height)
        } else {
            // 이미지가 더 세로로 김
            let width = slot.width // 너비는 슬롯에 딱 맞춤
            let height = width / imageAspect // 그 너비에 맞는 사진 높이로 확대
            let posY = slot.midY - height / 2 // 가운데 정렬(상하 잘림이 대칭)
            return CGRect(x: slot.minX, y: posY, width: width, height: height)
        }
    }
}

