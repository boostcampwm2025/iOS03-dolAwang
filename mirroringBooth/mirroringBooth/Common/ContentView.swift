//
//  ContentView.swift
//  mirroringBooth
//
//  Created by 이상유 on 2025-12-19.
//

import SwiftUI

struct ContentView: View {

    var body: some View {
        defaultView
    }
    
    @ViewBuilder
    var defaultView: some View {
        switch UIDevice.current.userInterfaceIdiom {
        case .phone:
            HomeView()
        default:
            AdvertiserView()
        }
    }
}

#Preview {
    ContentView()
}
