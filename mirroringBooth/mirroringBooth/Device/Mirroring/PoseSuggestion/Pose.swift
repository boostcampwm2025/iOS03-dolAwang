//
//  Pose.swift
//  mirroringBooth
//
//  Created by 이상유 on 2026-01-26.
//

import Foundation

struct Pose: Decodable, Hashable {
    let emoji: String
    let text: String

    var presentableText: String {
        let pattern =  #"(?<=[.!~])\s+"#
        return text.replacingOccurrences(
            of: pattern,
            with: "$1\n",
            options: .regularExpression
        )
    }
}
