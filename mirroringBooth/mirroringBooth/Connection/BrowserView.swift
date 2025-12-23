//
//  BrowserView.swift
//  mirroringBooth
//
//  Created by 이상유 on 2025-12-24.
//

import SwiftUI

struct BrowserView: View {

    private var router: Router
    @State private var connectionManager: Advertiser & Browser = ConnectionManager()

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

            Text(connectionManager.connectionState.values.joined(separator: "\n"))
                .font(.subheadline)

            ForEach(connectionManager.peers, id: \.self) { peer in
                deviceRow(peer)
            }
        }
        .onAppear {
            connectionManager.startBrowsing()
            connectionManager.startAdvertising()
        }
        .onDisappear {
            connectionManager.stopBrowsing()
            connectionManager.stopAdvertising()
        }
    }
    
    @ViewBuilder
    func deviceRow(_ peer: String) -> some View {
        Button {
            connectionManager.invite(to: peer)
        } label: {
            Text(peer)
                .padding(5)
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(style: StrokeStyle(lineWidth: 1))
                }
        }
    }
}

#Preview {
    BrowserView(Router())
}
