//
//  Router.swift
//  mirroringBooth
//
//  Created by 이상유 on 2026-01-07.
//

import SwiftUI

@Observable
final class Router {
    var path = NavigationPath()

    func push(to route: any Hashable) {
        path.append(route)
    }

    func pop() {
        path.removeLast()
    }

    func reset() {
        path.removeLast(path.count)
    }
}

enum CameraRoute: Hashable {
    case browsing
    case advertising
    case connectionList(ConnectionList, Browser)
}

struct ConnectionList: Hashable {
    let cameraName: String
    let mirroringName: String
    let remoteName: String?
}

enum MirroringRoute: Hashable {
    case modeSelection(Advertiser)
    case streaming(Advertiser, isTimerMode: Bool)
    case result(PhotoInformation)
}
