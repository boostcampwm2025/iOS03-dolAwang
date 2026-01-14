//
//  FrameAsset.swift
//  mirroringBooth
//
//  Created by 최윤진 on 1/14/26.
//

import SwiftUI

enum FrameAsset: String, CaseIterable {
    case black  //  블랙 색상
    case white  //  화이트 색상
    case crowded    //  이미지 어셋 이름
    case orange     //  이미지 어셋 이름
    case skyblue    //  이미지 어셋 이름

    enum UnifiedAsset {
        case color(Color)
        case image(Image)
    }

    func unifiedAsset() -> UnifiedAsset? {
        switch self {
        case .black:
            return .color(Color.black)
        case .white:
            return .color(Color.white)
        case .crowded, .orange, .skyblue:
            let assetName: String = self.rawValue
            if let uiImage = UIImage(named: assetName) {
                let imageValue = Image(uiImage: uiImage)
                return .image(imageValue)
            }
            return nil
        }
    }

    func unifiedAsset<T>(as typeValue: T.Type) -> T? {
        guard let unifiedAsset = self.unifiedAsset() else { return nil }
        switch unifiedAsset {
        case .color(let colorValue):
            return colorValue as? T
        case .image(let imageValue):
            return imageValue as? T
        }
    }
}
