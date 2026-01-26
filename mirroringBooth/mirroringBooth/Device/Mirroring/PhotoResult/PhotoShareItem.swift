//
//  PhotoShareItem.swift
//  mirroringBooth
//
//  Created by 윤대현 on 1/26/26.
//

import SwiftUI
import UniformTypeIdentifiers

struct PhotoShareItem: Transferable {
    let image: UIImage

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .jpeg) { item in
            guard let data = item.image.jpegData(compressionQuality: 1.0) else {
                throw TransferError.exportFailed
            }
            return data
        }
        .suggestedFileName("mirroringbooth_\\(Date().timeIntervalSince1970).jpg")
    }

    enum TransferError: Error {
        case exportFailed
    }
}
