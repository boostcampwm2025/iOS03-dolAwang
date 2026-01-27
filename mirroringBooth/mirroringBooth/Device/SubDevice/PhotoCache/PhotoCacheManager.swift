//
//  PhotoCacheManager.swift
//  mirroringBooth
//
//  Created by Liam on 1/13/26.
//

import Foundation
import OSLog
import UIKit

actor PhotoCacheManager {
    enum CachePath: String {
        case result = "result.jpg"
    }

    static let shared = PhotoCacheManager()

    private let sessionDirectory: URL
    private var cacheCount: Int = 0
    private var logger: Logger {
        Logger.photoCacheManager
    }

    var resultPhotoPath: URL {
        sessionDirectory.appendingPathComponent(CachePath.result.rawValue)
    }

    private init() {
        let cahcheDirectory = FileManager.default.urls(
            for: .cachesDirectory,
            in: .userDomainMask
        ).first!
        sessionDirectory = cahcheDirectory.appendingPathComponent("CurrentSession")
    }

    func startNewSession() {
        // 지난 캐시는 지우기(캐시는 세션 단위)
        clearCache()
        cacheCount = 0
        do {
            try FileManager.default.createDirectory(
                at: sessionDirectory,
                withIntermediateDirectories: true
            )
        } catch {
            logger.error("[Cache] 세션 폴더 생성 실패: \(error)")
        }
    }

    func savePhotoData(localURL: URL) throws {
        let fileURL = sessionDirectory.appendingPathComponent("photo\(cacheCount).jpg")
        try FileManager.default.moveItem(at: localURL, to: fileURL)
        logger.debug("[Cache] \(self.cacheCount)번 인덱스 사진 저장됨")
        cacheCount += 1
    }

    func saveResultImage(_ image: UIImage) throws {
        let fileURL = sessionDirectory.appendingPathComponent(CachePath.result.rawValue)
        if let data = image.jpegData(compressionQuality: 1.0) {
            try data.write(to: fileURL)
            logger.debug("[Cache] 결과 사진 저장됨")
        }
    }

    nonisolated func getPhotoURL(index: Int) -> URL {
        sessionDirectory.appendingPathComponent("photo\(index).jpg")
    }

    func clearCache() {
        if FileManager.default.fileExists(atPath: sessionDirectory.path) {
            try? FileManager.default.removeItem(at: sessionDirectory)
            logger.debug("[Cache] 캐시 폴더 삭제됨")
        }
    }
}
