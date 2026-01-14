//
//  PhotoFrameLayout.swift
//  mirroringBooth
//
//  Created by 이상유 on 2026-01-13.
//

import CoreGraphics

enum PhotoFrameLayout: CaseIterable, Identifiable {
    case twoByTwo, oneByOne, twoByOne, fourByOne, threeByTwo

    var id: Self { self }

    /// 프레임 스펙
    struct Spec {
        let size: CGSize   // 레이아웃 비율의 기준
        let slotFrame: [CGRect] // 슬롯 픽셀 rect
        var aspect: CGFloat { size.width / max(size.height, 1) }
    }

    var icon: String {
        switch self {
        case .twoByTwo:
            return "layout2x2"
        case .oneByOne:
            return "layout1x1"
        case .twoByOne:
            return "layout2x1"
        case .fourByOne:
            return "layout4x1"
        case .threeByTwo:
            return "layout3x2"
        }
    }

    var spec: Spec {
        switch self {
        case .twoByTwo:
            return .init(
                size: CGSize(width: 186, height: 270),
                slotFrame: [
                    CGRect(x: 10, y: 13, width: 80, height: 110),
                    CGRect(x: 96, y: 13, width: 80, height: 110),
                    CGRect(x: 10, y: 129, width: 80, height: 110),
                    CGRect(x: 96, y: 129, width: 80, height: 110)
                ]
            )

        case .oneByOne:
            return .init(
                size: CGSize(width: 96, height: 134),
                slotFrame: [
                    CGRect(x: 8, y: 8, width: 80, height: 100)
                ]
            )

        case .twoByOne:
            return .init(
                size: CGSize(width: 96, height: 239),
                slotFrame: [
                    CGRect(x: 8, y: 8, width: 80, height: 100),
                    CGRect(x: 8, y: 115, width: 80, height: 100)
                ]
            )

        case .fourByOne:
            return .init(
                size: CGSize(width: 96, height: 314),
                slotFrame: [
                    CGRect(x: 8, y: 8, width: 80, height: 65),
                    CGRect(x: 8, y: 80, width: 80, height: 65),
                    CGRect(x: 8, y: 151, width: 80, height: 65),
                    CGRect(x: 8, y: 222, width: 80, height: 65)
                ]
            )

        case .threeByTwo:
            return .init(
                size: CGSize(width: 268, height: 170),
                slotFrame: [
                    CGRect(x: 8, y: 8, width: 80, height: 65),
                    CGRect(x: 94, y: 8, width: 80, height: 65),
                    CGRect(x: 180, y: 8, width: 80, height: 65),
                    CGRect(x: 8, y: 80, width: 80, height: 65),
                    CGRect(x: 94, y: 80, width: 80, height: 65),
                    CGRect(x: 180, y: 80, width: 80, height: 65)
                ]
            )
        }
    }

    /// 프리뷰/렌더링 공용: 정규화 슬롯(0~1)
    func frameRects() -> [CGRect] {
        let width = spec.size.width
        let height = spec.size.height
        guard width > 0, height > 0 else { return [] }

        return spec.slotFrame.map { rect in
            CGRect(
                x: rect.minX / width,
                y: rect.minY / height,
                width: rect.width / width,
                height: rect.height / height
            )
        }
    }

    /// 프리뷰 컨테이너 비율은 "가상 프레임 비율"
    var previewAspect: CGFloat { spec.aspect }
}

extension CGRect {
    /// 정규화(0~1) rect를 실제 캔버스 rect로 변환
    func denormalized(in size: CGSize) -> CGRect {
        CGRect(
            x: minX * size.width,
            y: minY * size.height,
            width: width * size.width,
            height: height * size.height
        )
    }
}
