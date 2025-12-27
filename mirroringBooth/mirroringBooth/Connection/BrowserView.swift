//
//  BrowserView.swift
//  mirroringBooth
//
//  Created by 이상유 on 2025-12-24.
//

import SwiftUI

struct BrowserView: View {

    private var router: Router
    private var connectionManager: Advertiser & Browser
    @State private var isConnecting = false

    init(_ router: Router, _ connectionManager: Advertiser & Browser) {
        self.router = router
        self.connectionManager = connectionManager
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

            if isConnecting {
                ProgressView()
                    .padding()
                Text("연결 중...")
                    .font(.subheadline)
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
        .onChange(of: connectionManager.connectionState) { _, newValue in
            // 연결이 완료되면 카메라 화면으로 이동
            if newValue.values.contains(where: { $0.contains("연결 완료") }) && isConnecting {
                isConnecting = false
                router.push(to: .camera)
            }
        }
    }
    
    @ViewBuilder
    func deviceRow(_ peer: String) -> some View {
        Button {
            connectionManager.invite(to: peer)
            isConnecting = true
        } label: {
            Text(peer)
                .padding(5)
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(style: StrokeStyle(lineWidth: 1))
                }
        }
        .disabled(isConnecting)
    }
}

#Preview {
    BrowserView(Router(), ConnectionManager())
}
