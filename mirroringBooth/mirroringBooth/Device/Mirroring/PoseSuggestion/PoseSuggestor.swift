//
//  PoseSuggestor.swift
//  mirroringBooth
//
//  Created by 이상유 on 2026-01-26.
//

struct PoseSuggestor {
    private static let allPoses: [Pose: PoseMeta] = PoseRepository.poses

    static func suggest(count: Int) -> [PoseMeta] {
        return Pose.allCases.shuffled().prefix(count).compactMap { allPoses[$0] }
    }
}
