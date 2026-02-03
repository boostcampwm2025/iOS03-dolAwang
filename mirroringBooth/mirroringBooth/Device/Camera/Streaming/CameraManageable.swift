//
//  CameraManageable.swift
//  mirroringBooth
//
//  Created by 이상유 on 2/2/26.
//

import AVFoundation

protocol CameraManageable: AnyObject {
    var rawData: ((CMSampleBuffer) -> Void)? { get set }
    var onEncodedData: ((Data) -> Void)? { get set }
    var onTransferCompleted: (() -> Void)? { get set }
    var onAllPhotosStored: ((Int) -> Void)? { get set }

    func startSession()
    func stopSession()
    func capturePhoto(_ orientation: CameraOrientation)
    func sendAllPhotos(using browser: Browser)
}
