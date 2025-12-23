//
//  BrowserView.swift
//  mirroringBooth
//
//  Created by 이상유 on 2025-12-24.
//

import SwiftUI

struct BrowserView: View {

    private var router: Router
    @State private var connectionManager = ConnectionManager()

    init(_ router: Router) {
        self.router = router
    }

    var body: some View {
        VStack {
            Button {
                router.pop()
            } label: {
                Text("뒤로가기")
                    .font(.headline)
                    .padding(5)
            }

            Text(connectionManager.connectionState)
                .font(.subheadline)

            Text(connectionManager.peers.joined(separator: ", "))
        }
        .onAppear {
            connectionManager.startBrowsing()
        }
        .onDisappear {
            connectionManager.stopBrowsing()
        }
    }
}

#Preview {
    BrowserView(Router())
}
