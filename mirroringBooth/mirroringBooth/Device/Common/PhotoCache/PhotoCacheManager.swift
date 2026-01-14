//
//  PhotoCacheManager.swift
//  mirroringBooth
//
//  Created by Liam on 1/13/26.
//

import Foundation
import OSLog
import UIKit

final class PhotoCacheManager {
    static let shared = PhotoCacheManager()

    private let sessionDirectory: URL
    private var cacheCount: Int = 0
    private var logger: Logger {
        Logger.photoCacheManager
    }

    private init() {
        // 앱 껐다 켰을 때 캐시를 원하는 것이 아니므로 Library/Caches보다 tmp 선택.
        // 문제가 발생할 경우 변경 고려
        let cahcheDirectory = FileManager.default.temporaryDirectory
        sessionDirectory = cahcheDirectory.appendingPathComponent("CurrentSession")
    }

    func startNewSession() async {
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

    func savePhotoData(localURL: URL) async throws {
        let fileURL = sessionDirectory.appendingPathComponent("photo\(cacheCount).jpg")
        try FileManager.default.moveItem(at: localURL, to: fileURL)
        logger.debug("[Cache] \(self.cacheCount)번 인덱스 사진 저장됨")
        cacheCount += 1
    }

    func getPhotoURL(index: Int) -> URL {
        sessionDirectory.appendingPathComponent("photo\(index).jpg")
    }

    func clearCache() {
        if FileManager.default.fileExists(atPath: sessionDirectory.path) {
            try? FileManager.default.removeItem(at: sessionDirectory)
            logger.debug("[Cache] 캐시 폴더 삭제됨")
        }
    }
}
