//
//  FoundPeersView.swift
//  mirroringBooth
//
//  Created by Gemini on 12/30/25.
//

import SwiftUI
import MultipeerConnectivity

struct FoundPeersView: View {
    @ObservedObject var manager: MultipeerManager

    var body: some View {
        List(manager.browser!.foundPeers, id: \.self) { peer in
            Button(action:{
                manager.browser!.invite(peer)
            }) {
                Text(peer.displayName)
            }
        }
    }
}
