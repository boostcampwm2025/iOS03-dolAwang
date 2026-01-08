//
//  AnimalRepository.swift
//  mirroringBooth
//
//  Created by 이상유 on 2026-01-08.
//

import Foundation
import OSLog

struct AnimalRepository {
    static let animals: [String] = {
        guard
            let url = Bundle.main.url(forResource: "Animals", withExtension: "plist"),
            let animals = NSArray(contentsOf: url) as? [String]
        else {
            Logger.animalRepository.error("Animals.plist 로드 실패")
            return ["동물"]
        }
        return animals
    }()
}
