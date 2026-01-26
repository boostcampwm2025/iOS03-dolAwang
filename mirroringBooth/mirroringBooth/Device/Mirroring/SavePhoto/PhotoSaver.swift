//
//  PhotoManager.swift
//  mirroringBooth
//
//  Created by Liam on 1/26/26.
//

import Photos
import UIKit

struct PhotoSaver {
    func saveImage(image: UIImage, completion: @escaping (Bool, Error?) -> Void) {
        // 권한 확인
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            guard status == .authorized || status == .limited else {
                completion(false, nil)
                return
            }
            // 라이브러리 저장
            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            } completionHandler: { result, error in
                DispatchQueue.main.async {
                    completion(result, error)
                }
            }
        }
    }
}
