//
//  PlistRepository.swift
//  mirroringBooth
//
//  Created by 이상유 on 2026-01-27.
//

import Foundation
import OSLog

struct PlistRepository {
    static let animals: [String] = load("Animals")
    static let poses: [Pose] = load("PoseData")

    private static func load<T: Decodable>(_ resource: String) -> [T] {
        guard let url = Bundle.main.url(forResource: resource, withExtension: "plist") else {
            Logger.plistRepository.error("\(resource).plist 파일을 찾을 수 없음")
            return []
        }
        guard let data = try? Data(contentsOf: url) else {
            Logger.plistRepository.error("\(resource).plist 데이터를 불러올 수 없음")
            return []
        }
        guard let items = try? PropertyListDecoder().decode([T].self, from: data) else {
            Logger.plistRepository.error("\(resource).plist 디코딩 실패")
            return []
        }
        return items
    }
}
