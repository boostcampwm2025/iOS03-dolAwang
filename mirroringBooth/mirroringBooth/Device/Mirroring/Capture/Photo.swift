//
//  Photo.swift
//  mirroringBooth
//
//  Created by 윤대현 on 1/3/26.
//

import Foundation

// View 표시용 모델
struct Photo: Identifiable {
    let id: UUID
    var url: URL
    var selectNumber: Int?
}
