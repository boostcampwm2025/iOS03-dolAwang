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

        await withTaskGroup(of: (Int, UIImage?).self) { taskGroup in
            for (index, photo) in photos.enumerated() {
                taskGroup.addTask {
                    let loadedPhotoImage = await loadImage(from: photo.url)
                    return (index, loadedPhotoImage)
                }
            }

            for await (index, loadedPhotoImage) in taskGroup {
                loadedPhotoImages[index] = loadedPhotoImage
            }
        }

        return loadedPhotoImages
    }

    static func loadImage(from photoUrl: URL) async -> UIImage? {
        await Task.detached(priority: .userInitiated) {
            UIImage(contentsOfFile: photoUrl.path(percentEncoded: false))
        }.value
    }
}
