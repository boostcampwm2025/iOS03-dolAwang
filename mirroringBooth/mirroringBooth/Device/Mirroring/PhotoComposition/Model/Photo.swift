//
//  Photo.swift
//  mirroringBooth
//
//  Created by 윤대현 on 1/3/26.
//

import Foundation

// View 표시용 모델
struct Photo: Identifiable, Hashable {
    let id: UUID
    let url: URL
    var selectNumber: Int?

    static func == (lhs: Photo, rhs: Photo) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
