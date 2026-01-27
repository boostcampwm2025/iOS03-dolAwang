//
//  PoseSuggestor.swift
//  mirroringBooth
//
//  Created by 이상유 on 2026-01-26.
//

struct PoseSuggestor {
    static func suggest(count: Int) -> [Pose] {
        Array(PlistRepository.poses.shuffled().prefix(count))
    }
}
