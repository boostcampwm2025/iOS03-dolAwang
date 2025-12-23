//
//  Router.swift
//  mirroringBooth
//
//  Created by 이상유 on 2025-12-24.
//

import Foundation

@Observable
final class Router {
    var path: [Route] = []
    
    func push(to route: Route) {
        path.append(route)
    }
    
    func pop() {
        path.removeLast()
    }
    
    func reset() {
        path.removeLast(path.count)
    }
}

enum Route {
    case connection
}
