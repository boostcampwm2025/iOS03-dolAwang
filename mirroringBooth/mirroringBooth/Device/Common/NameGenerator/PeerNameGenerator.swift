//
//  PeerNameGenerator.swift
//  mirroringBooth
//
//  Created by 이상유 on 2026-01-08.
//

struct PeerNameGenerator {

    private static let animals: [String] = AnimalRepository.animals

    static func randomCode(length: Int) -> String {
        let chars = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890")
        return String((0..<length).compactMap { _ in chars.randomElement() })
    }

    static func makeDisplayName(isRandom: Bool, with deviceName: String) -> String {
        let user = isRandom ? animals.randomElement() ?? "동물" : "나"
        let code = randomCode(length: 3)
        return "\(user)의 \(deviceName) · \(code)"
    }

}
