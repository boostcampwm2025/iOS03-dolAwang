//
//  PoseRepository.swift
//  mirroringBooth
//
//  Created by 이상유 on 2026-01-26.
//

import Foundation
import OSLog

struct PoseRepository {
    static let poses: [Pose: PoseMeta] = {
        guard
            let url = Bundle.main.url(forResource: "PoseData", withExtension: "plist"),
            let data = try? Data(contentsOf: url),
            let raw = try? PropertyListDecoder().decode([String: PoseMeta].self, from: data)
        else {
            Logger.poseRepository.log("PoseData.plist 로드 실패")
            return [:]
        }

        var result: [Pose: PoseMeta] = [:]

        for (key, value) in raw {
            guard let pose = Pose(rawValue: key) else {
                Logger.poseRepository.log("\(key)를 찾을 수 없음")
                continue
            }
            result[pose] = value
        }

        return result
    }()
}
