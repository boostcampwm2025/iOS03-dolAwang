//
//  PhotoFrameLayout.swift
//  mirroringBooth
//
//  Created by 이상유 on 2026-01-13.
//

import CoreGraphics

enum PhotoFrameLayout: CaseIterable, Identifiable {
    case oneByOne, twoByOne, fourByOne, twoByTwo, twoByThree

    var id: Self { self }

    var capacity: Int {
        switch self {
        case .oneByOne: return 1
        case .twoByOne: return 2
        case .fourByOne: return 4
        case .twoByTwo: return 4
        case .twoByThree: return 6
        }
    }

    // 공간을 정규화 (0-1 좌표)
    // 반환된 공간들은 역정규화를 통해 제 위치를 찾아갈 수 있다.
    func frameRects(
        outerInsetVertical: CGFloat = 0.02,
        outerInsetHorizontal: CGFloat = 0.04,
        spacing: CGFloat = 0.03
    ) -> [CGRect] {
        let safe = Self.safeArea(
            outerInsetVertical: outerInsetVertical,
            outerInsetHorizontal: outerInsetHorizontal
        )
        switch self {
        case .oneByOne: return Self.normalizeFrameRects(safeArea: safe, spacing: spacing, cols: 1, rows: 1)
        case .twoByOne: return Self.normalizeFrameRects(safeArea: safe, spacing: spacing, cols: 1, rows: 2)
        case .fourByOne: return Self.normalizeFrameRects(safeArea: safe, spacing: spacing, cols: 1, rows: 4)
        case .twoByTwo: return Self.normalizeFrameRects(safeArea: safe, spacing: spacing, cols: 2, rows: 2)
        case .twoByThree: return Self.normalizeFrameRects(safeArea: safe, spacing: spacing, cols: 2, rows: 3)
        }
    }

    // 프레임에 사진이 들어갈 공간들을 계산
    private static func normalizeFrameRects(
        safeArea: CGRect,
        spacing: CGFloat,
        cols: Int,
        rows: Int
    ) -> [CGRect] {
        var results: [CGRect] = []

        // 사진 사이에 들어갈 간격의 전체 길이
        let totalSpacingX = spacing * CGFloat(cols - 1)
        let totalSpacingY = spacing * CGFloat(rows - 1)

        // 사진 하나의 크기: (전체 사용 가능 공간 - 간격 총합) ÷ 사진 개수
        let cellWidth = (safeArea.width - totalSpacingX) / CGFloat(cols)
        let cellHeight = (safeArea.height - totalSpacingY) / CGFloat(rows)

        // 결과 배열 준비 (성능 최적화)
        results.reserveCapacity(rows * cols)

        for row in 0..<rows {
            for col in 0..<cols {
                // 몇번쨰 사진인지에 따른 위치 계산
                let posX = safeArea.minX + (cellWidth + spacing) * CGFloat(col)
                let posY = safeArea.minY + (cellHeight + spacing) * CGFloat(row)
                let rect = CGRect(x: posX, y: posY, width: cellWidth, height: cellHeight)
                results.append(rect)
            }
        }
        return results
    }

    // 프레임 내부에서 실제 사진들이 들어갈 안젼 영역
    private static func safeArea(
        outerInsetVertical: CGFloat,
        outerInsetHorizontal: CGFloat
    ) -> CGRect {
        return CGRect(
            x: outerInsetHorizontal,
            y: outerInsetVertical,
            width: 1 - 2 * outerInsetHorizontal,
            height: 1 - 2 * outerInsetVertical
        )
    }
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
