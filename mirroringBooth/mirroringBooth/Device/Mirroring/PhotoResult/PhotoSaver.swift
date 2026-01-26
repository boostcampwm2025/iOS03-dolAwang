//
//  PhotoManager.swift
//  mirroringBooth
//
//  Created by Liam on 1/26/26.
//

import Photos
import UIKit

struct PhotoSaver {
    static let albumName: String = "Mirroring Booth"

    static func saveImage(image: UIImage, completion: @escaping (Bool, Error?) -> Void) {
        // 권한 확인
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            guard status == .authorized || status == .limited else {
                completion(false, nil)
                return
            }

            getAlbum { album in
                saveImageToAlbum(image: image, album: album, completion: completion)
            }
        }
    }

    private static func getAlbum(completion: @escaping (PHAssetCollection?) -> Void) {
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", albumName)
        let collection = PHAssetCollection.fetchAssetCollections(
            with: .album,
            subtype: .any,
            options: fetchOptions
        )

        if let album = collection.firstObject {
            completion(album)
        } else {
            // 없으면 새로 생성
            PHPhotoLibrary.shared().performChanges({
                PHAssetCollectionChangeRequest
                    .creationRequestForAssetCollection(withTitle: albumName)
            }, completionHandler: { success, _ in
                if success {
                    let collection = PHAssetCollection.fetchAssetCollections(
                        with: .album,
                        subtype: .any,
                        options: fetchOptions
                    )
                    completion(collection.firstObject)
                } else {
                    completion(nil)
                }
            })
        }
    }

    private static func saveImageToAlbum(
        image: UIImage,
        album: PHAssetCollection?,
        completion: @escaping (Bool, Error?) -> Void
    ) {
        PHPhotoLibrary.shared().performChanges({
            let assetRequest = PHAssetChangeRequest.creationRequestForAsset(from: image)

            if let album = album,
               let placeholder = assetRequest.placeholderForCreatedAsset,
               let albumRequest = PHAssetCollectionChangeRequest(for: album) {
                albumRequest.addAssets([placeholder] as NSArray)
            }
        }) { success, error in
            DispatchQueue.main.async {
                completion(success, error)
            }
        }
    }
}
