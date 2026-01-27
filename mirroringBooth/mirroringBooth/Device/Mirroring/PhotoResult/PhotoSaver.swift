//
//  PhotoManager.swift
//  mirroringBooth
//
//  Created by Liam on 1/26/26.
//

import OSLog
import Photos
import UIKit

struct PhotoSaver {
    static let albumName: String = "Mirroring Booth"

    static func saveImage(image: UIImage, completion: @escaping (Bool, Error?) -> Void) {
        switch PHPhotoLibrary.authorizationStatus(for: .addOnly) {
        case .authorized, .limited:
            getAlbum { album in
                saveImageToAlbum(image: image, album: album, completion: completion)
            }
        case .notDetermined, .denied, .restricted:
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
                guard status == .authorized || status == .limited else {
                    Logger.photoSaver.debug("[사진 저장] 사진 권한: \(status.rawValue)")
                    completion(false, nil)
                    return
                }
            }
        @unknown default:
                break
        }
    }

    static func openSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(settingsURL)
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
            Logger.photoSaver.debug("[사진 저장] 기존 앨범 발견")
            completion(album)
        } else {
            // 없으면 새로 생성
            PHPhotoLibrary.shared().performChanges {
                PHAssetCollectionChangeRequest
                    .creationRequestForAssetCollection(withTitle: albumName)
            } completionHandler: { success, error in
                if success {
                    let collection = PHAssetCollection.fetchAssetCollections(
                        with: .album,
                        subtype: .any,
                        options: fetchOptions
                    )
                    Logger.photoSaver.debug("[사진 저장] 신규 앨범 생성")
                    completion(collection.firstObject)
                } else {
                    Logger.photoSaver.error("[사진 저장] 앨범 생성 실패: \(error)")
                    completion(nil)
                }
            }
        }
    }

    private static func saveImageToAlbum(
        image: UIImage,
        album: PHAssetCollection?,
        completion: @escaping (Bool, Error?) -> Void
    ) {
        PHPhotoLibrary.shared().performChanges {
            let assetRequest = PHAssetChangeRequest.creationRequestForAsset(from: image)

            if let album = album,
               let placeholder = assetRequest.placeholderForCreatedAsset,
               let albumRequest = PHAssetCollectionChangeRequest(for: album) {
                albumRequest.addAssets([placeholder] as NSArray)
            }
        } completionHandler: { success, error in
            DispatchQueue.main.async {
                Logger.photoSaver.debug("[사진 저장] 저장 \(success ? "성공" : "실패")")
                completion(success, error)
            }
        }
    }
}
