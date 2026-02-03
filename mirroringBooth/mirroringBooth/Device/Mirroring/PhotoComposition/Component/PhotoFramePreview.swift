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
            ZStack(alignment: .topLeading) {
                // 1. 프레임 (배경)
                if let frameImage = information.frame.image {
                    Image(uiImage: frameImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                }

                // 2. 사진 슬롯들
                let slots = information.layout.frameRects().map { $0.denormalized(in: size) }
                ForEach(Array(zip(slots.indices, slots)), id: \.0) { index, slot in
                    Group {
                        if index < information.photos.count {
                            LocalAsyncImage(
                                url: information.photos[index].url,
                                slotAspect: slot.width / slot.height
                            )
                        } else {
                            RoundedRectangle(cornerRadius: 5)
                                .fill(information.frame == .white ? .gray : .white)
                        }
                    }
                    .frame(width: slot.width, height: slot.height)
                    .offset( x: slot.minX, y: slot.minY)
                }

                // 3. 날짜
                let (backgroundRect, textRect) = dateRects(parentSize: size)

                if let backgroundName = information.frame.dateBackgroundName,
                   let image = UIImage(named: backgroundName) {
                    let target = aspectFillRect(for: image.size, into: backgroundRect)
                        .insetBy(
                            dx: -(textRect.width * 0.35),
                            dy: -(textRect.height * 0.2)
                        )

                    Image(uiImage: image)
                        .resizable()
                        .frame(width: target.width, height: target.height)
                        .offset(x: target.minX, y: target.minY)
                }

                Text(formattedToday())
                    .foregroundStyle(information.frame.textColor)
                    .font(.system(size: dateFontSize(parentSize: size)).bold())
                    .frame(width: textRect.width, height: textRect.height, alignment: .topLeading)
                    .offset(x: textRect.minX, y: textRect.minY)
            }
        }
        .aspectRatio(information.layout.previewAspect, contentMode: .fit)
        .clipped()
    }

    private func formattedToday() -> String {
        Date().formatted(
            .dateTime.year(.defaultDigits)
            .month(.twoDigits)
            .day(.twoDigits)
        )
        .replacingOccurrences(of: "-", with: ".")
    }

    private func dateFontSize(parentSize: CGSize) -> CGFloat {
        max(parentSize.width, parentSize.height) * 0.03
    }

    private func measureDateTextSize(parentSize: CGSize) -> CGSize {
        let text = formattedToday()
        let font = UIFont.systemFont(
            ofSize: dateFontSize(parentSize: parentSize),
            weight: .bold
        )

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font
        ]

        return (text as NSString).size(withAttributes: attributes)
    }

    private func dateRects(parentSize: CGSize) -> (CGRect, CGRect) {
        let normalizedOrigin = information.layout.dateOrigin()
        let dateOrigin = CGPoint(
            x: normalizedOrigin.x * parentSize.width,
            y: normalizedOrigin.y * parentSize.height
        )

        let textSize = measureDateTextSize(parentSize: parentSize)

        let padding: CGFloat = 4
        let backgroundRect = CGRect(
            x: dateOrigin.x,
            y: dateOrigin.y,
            width: textSize.width + padding * 2,
            height: textSize.height + padding
        )

        let textRect = CGRect(
            x: dateOrigin.x + padding,
            y: dateOrigin.y + padding / 2,
            width: textSize.width,
            height: textSize.height
        )

        return (backgroundRect, textRect)
    }

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
