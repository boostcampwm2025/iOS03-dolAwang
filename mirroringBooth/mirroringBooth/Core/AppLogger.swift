//
//  AppLogger.swift
//  mirroringBooth
//
//  Created by 윤대현 on 12/29/25.
//

import OSLog

extension Logger {
    private static var subsystem = Bundle.main.bundleIdentifier ?? "kr.codesquad.boostcamp10.dolAwang.mirroringBooth"

    static let advertiser = Logger(subsystem: subsystem, category: "Advertiser")
    static let browser = Logger(subsystem: subsystem, category: "Browser")
    static let h264encoder = Logger(subsystem: subsystem, category: "H264Encoder")
    static let h264decoder = Logger(subsystem: subsystem, category: "H264Decoder")
    static let cameraManager = Logger(subsystem: subsystem, category: "CameraManager")
    static let animalRepository = Logger(subsystem: subsystem, category: "AnimalRepository")
    static let watchConnectionManager = Logger(subsystem: subsystem, category: "WatchConnectionManager")
}
