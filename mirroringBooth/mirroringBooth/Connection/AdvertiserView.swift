//
//  AdvertiserView.swift
//  mirroringBooth
//
//  Created by 이상유 on 2025-12-24.
//

import SwiftUI

struct AdvertiserView: View {
    
    private var connectionManager: Advertiser
    
    init(_ connectionManager: Advertiser) {
        self.connectionManager = connectionManager
    }
    
    var body: some View {
        VStack{
            if connectionManager.connectionState.isEmpty {
                Text("아이폰에서 연결을 시도해주세요...")
            } else {
                Text(connectionManager.connectionState.values.joined(separator: "\n"))
                    .font(.subheadline)
            }
        }
        .onAppear {
            connectionManager.startAdvertising()
        }
        .onDisappear {
            connectionManager.stopAdvertising()
        }
    }
}

#Preview {
    AdvertiserView(ConnectionManager())
}
