//
//  ReceivedCameraView.swift
//  mirroringBooth
//
//  Created by Liam on 1/1/26.
//

import SwiftUI

struct ReceivedCameraView: View {
    @ObservedObject var multipeerManager: MultipeerManager
    
    var body: some View {
        if let image = multipeerManager.receivedImage {
            Image(decorative: image, scale: 1.0, orientation: .up)
                .resizable()
                .scaledToFit()
        } else {
            Text("영상 수신 대기 중...")
        }
    }
}
