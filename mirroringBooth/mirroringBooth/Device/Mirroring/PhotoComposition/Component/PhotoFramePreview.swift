//
//  PhotoFramePreview.swift
//  mirroringBooth
//
//  Created by 이상유 on 2026-01-14.
//

import SwiftUI

struct PhotoFramePreview: View {
    let information: PhotoInformation

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size

            Canvas { context, _ in
                let canvas = CGRect(origin: .zero, size: size)

                // 1. 프레임 (배경)
                if let frameImage = information.frame.image {
                    let frameTarget = aspectFillRect(for: frameImage.size, into: canvas)
                    context.draw(Image(uiImage: frameImage), in: frameTarget)
                }

                // 2. 사진 슬롯들
                let slots = information.layout.frameRects().map { $0.denormalized(in: size) }
                for (index, slot) in slots.enumerated() {
                    context.drawLayer { layer in
                        layer.clip(to: Path(roundedRect: slot, cornerRadius: 5))

                        if index < information.photos.count,
                           let photoData = information.photos[index].imageData,
                           let photo = UIImage(data: photoData) {
                            let target = aspectFillRect(for: photo.size, into: slot)
                            layer.draw(Image(uiImage: photo), in: target)
                        } else {
                            layer.fill(
                                Path(roundedRect: slot, cornerRadius: 5),
                                with: .color(information.frame == .white
                                             ? .gray
                                             : .white)
                            )
                        }
                    }
                }

                // 3. 날짜
                let (resolvedText, textSize) = calculateDateViewSize(parentSize: size, with: context)
                let (backgroundRect, textRect) = dateRects(
                    parentSize: size,
                    resolvedText: resolvedText,
                    textSize: textSize
                )

                if let backgroundName = information.frame.dateBackgroundName {
                    if let image = UIImage(named: backgroundName) {
                        let target = aspectFillRect(for: image.size, into: backgroundRect)
                            .insetBy(
                                dx: -(textSize.width * 0.35),
                                dy: -(textSize.height * 0.2)
                            )
                        context.draw(Image(uiImage: image), in: target)
                    }
                }

                context.draw(resolvedText, in: textRect)
            }
        }
        .aspectRatio(information.layout.previewAspect, contentMode: .fit)
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

    /// 날짜 텍스트 뷰 생성 및 크기 계산
    private func calculateDateViewSize(
        parentSize: CGSize,
        with context: GraphicsContext
    ) -> (GraphicsContext.ResolvedText, CGSize) {
        // 1. 현재 날짜 계산 및 형식 정리
        let today = Date().formatted(
            .dateTime.year(.defaultDigits)
            .month(.twoDigits)
            .day(.twoDigits)
        ).replacingOccurrences(of: "-", with: ".")

        // 2. 텍스트 크기 계산 및 스타일 설정
        let fontSize = max(parentSize.width, parentSize.height) * 0.03
        let dateText = Text(today)
            .foregroundStyle(information.frame.textColor)
            .font(.system(size: fontSize).bold())

        // 3. 텍스트 뷰 크기 계산
        let resolvedText = context.resolve(dateText)
        let textSize = resolvedText.measure(in: CGSize(
            width: CGFloat.greatestFiniteMagnitude,
            height: CGFloat.greatestFiniteMagnitude
        ))

        return (resolvedText, textSize)
    }

    /// 날짜 배경 슬롯과 날짜 텍스트 슬롯 생성
    private func dateRects(
        parentSize: CGSize,
        resolvedText: GraphicsContext.ResolvedText,
        textSize: CGSize
    ) -> (CGRect, CGRect) {
        // 1. 날짜 입력 시작할 포인트 계산
        let normalizedOrigin = information.layout.dateOrigin()
        let dateOrigin = CGPoint(
            x: normalizedOrigin.x * parentSize.width,
            y: normalizedOrigin.y * parentSize.height
        )

        // 2. 배경 슬롯
        let padding: CGFloat = 4
        let backgroundRect = CGRect(
            x: dateOrigin.x,
            y: dateOrigin.y,
            width: textSize.width + padding * 2,
            height: textSize.height + padding
        )

        // 3. 텍스트 슬롯
        let textRect = CGRect(
            x: dateOrigin.x + padding,
            y: dateOrigin.y + padding / 2,
            width: textSize.width,
            height: textSize.height
        )

        return (backgroundRect, textRect)
    }
}
