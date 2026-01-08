//
//  FrameView.swift
//  mirroringBooth
//
//  Created by Liam on 1/8/26.
//

import SwiftUI

struct FrameView: View {
    let photos: [Photo]
    let rows: Int
    let columns: Int
    let frameColor: Color

    enum Ratio: CGFloat {
        case side = 9.0
        case center = 7.0
        case photoHeight = 63.0
        case photoWidth = 84.0
        case bottom = 45
    }

    var width: CGFloat {
        Ratio.photoWidth.rawValue * CGFloat(columns)
        + Ratio.center.rawValue * CGFloat(columns - 1)
        + Ratio.side.rawValue * 2.0
    }

    var height: CGFloat {
        Ratio.side.rawValue + Ratio.bottom.rawValue
        + Ratio.center.rawValue * CGFloat(rows - 1)
        + Ratio.photoHeight.rawValue * CGFloat(rows)
    }

    private func calculatePosition(row: Int, col: Int) -> (CGFloat, CGFloat) {
        let startX = Ratio.side.rawValue + CGFloat(col) * (Ratio.photoWidth.rawValue + Ratio.center.rawValue)
        let startY = Ratio.side.rawValue + CGFloat(row) * (Ratio.photoHeight.rawValue + Ratio.center.rawValue)
        let centerX = startX + (Ratio.photoWidth.rawValue / 2)
        let centerY = startY + (Ratio.photoHeight.rawValue / 2)
        return (centerX/width, centerY/height)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(0..<rows, id: \.self) { row in
                    ForEach(0..<columns, id: \.self) { col in
                        let (normX, normY) = calculatePosition(row: row, col: col)
                        let rectWidth = geometry.size.width * (Ratio.photoWidth.rawValue / width)
                        let rectHeight = geometry.size.height * (Ratio.photoHeight.rawValue / height)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray)
                            .frame(width: rectWidth, height: rectHeight)
                            .position(x: geometry.size.width * normX, y: geometry.size.height * normY)
                    }
                }

                ForEach(Array(photos.enumerated()), id: \.element.id) { index, photo in
                    let row = index / columns
                    let col = index % columns

                    let (normX, normY) = calculatePosition(row: row, col: col)
                    let rectWidth = geometry.size.width * (Ratio.photoWidth.rawValue / width)
                    let rectHeight = geometry.size.height * (Ratio.photoHeight.rawValue / height)
                    if case let .completed(data) = photo.state,
                       let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(width: rectWidth, height: rectHeight)
                            .clipped()
                            .position(x: geometry.size.width * normX, y: geometry.size.height * normY)
                    }
                }
            }
        }
        .aspectRatio(width / height, contentMode: .fit)
        .background(frameColor)
    }
}

#Preview {
    FrameView(rows: 3, columns: 2, frameColor: .blue)
}
