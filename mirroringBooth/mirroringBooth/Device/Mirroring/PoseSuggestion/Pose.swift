//
//  Pose.swift
//  mirroringBooth
//
//  Created by 이상유 on 2026-01-26.
//

import Foundation

struct Pose: Decodable, Hashable {
    let emoji: String
    let description: String
    let summary: String

    var presentableText: String {
        let pattern =  #"(?<=[.!~])\s+"#
        return description.replacingOccurrences(
            of: pattern,
            with: "\n",
            options: .regularExpression
        )
    }
}
