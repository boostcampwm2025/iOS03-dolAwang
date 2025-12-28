//
//  AppLogger.swift
//  mirroringBooth
//
//  Created by 윤대현 on 12/29/25.
//

import Foundation
import os

enum AppLogger {

    private static let subsystem =
        Bundle.main.bundleIdentifier
        ?? "kr.codesquad.boostcamp10.dolAwang.mirroringBooth"

    static func make(category: String) -> Logger {
        Logger(subsystem: subsystem, category: category)
    }

    static func make<T>(for type: T.Type) -> Logger {
        Logger(
            subsystem: subsystem,
            category: String(describing: type)
        )
    }
}
