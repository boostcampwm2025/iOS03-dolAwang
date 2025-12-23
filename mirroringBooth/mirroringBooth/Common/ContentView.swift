//
//  ContentView.swift
//  mirroringBooth
//
//  Created by 이상유 on 2025-12-19.
//

import SwiftUI

struct ContentView: View {
    
    @State private var router: Router = .init()

    var body: some View {
        NavigationStack(path: $router.path) {
            HomeView(router)
                .navigationDestination(for: Route.self) { viewType in
                    switch viewType {
                    case .connection:
                        BrowserView(router)
                    }
                }
        }
    }
}

#Preview {
    ContentView()
}
