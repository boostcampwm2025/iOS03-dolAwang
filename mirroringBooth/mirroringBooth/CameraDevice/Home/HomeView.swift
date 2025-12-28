//
//  HomeView.swift
//  mirroringBooth
//
//  Created by 이상유 on 2025-12-24.
//

import SwiftUI

struct HomeView: View {
    
    @State private var router: Router = .init()
    private let sender = VideoSender()

    var body: some View {
        NavigationStack(path: $router.path) {
            Button {
                router.push(to: .connection)
            } label: {
                Text("촬영하기")
                    .font(.headline)
                    .padding(5)
            }
            .navigationDestination(for: Route.self) { viewType in
                switch viewType {
                case .connection:
                    BrowserView(router, sender)
                case .camera:
                    StreamingView(sender)
                }
            }
        }
    }
    
}

#Preview {
    HomeView()
}
