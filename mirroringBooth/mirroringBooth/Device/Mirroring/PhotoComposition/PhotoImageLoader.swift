//
//  PhotoImageLoader.swift
//  mirroringBooth
//
//  Created by 최윤진 on 2026-03-09.
//

import UIKit

enum PhotoImageLoader {
    static func loadImages(from photos: [Photo]) async -> [UIImage?] {
        var loadedPhotoImages = [UIImage?](repeating: nil, count: photos.count)

        for (index, photo) in photos.enumerated() {
            loadedPhotoImages[index] = await loadImage(from: photo.url)
        }

        return loadedPhotoImages
    }

    static func loadImage(from photoUrl: URL) async -> UIImage? {
        await Task.detached(priority: .userInitiated) {
            UIImage(contentsOfFile: photoUrl.path(percentEncoded: false))
        }.value
    }
}
