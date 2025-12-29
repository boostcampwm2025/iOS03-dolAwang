//
//  Logger+.swift
//  mirroringBooth
//
//  Created by Liam on 12/29/25.
//

import OSLog

extension Logger {
    private static var subsystem = Bundle.main.bundleIdentifier ?? "kr.codesquad.boostcamp10.dolAwang.mirroringBooth"
    
    static let multipeerAdvertiser = Logger(subsystem: subsystem, category: "MultipeerAdvertiser")
    static let multipeerBrowser = Logger(subsystem: subsystem, category: "MultipeerBrowser")
    static let multipeerManager = Logger(subsystem: subsystem, category: "MultipeerManager")
}
