//
//  Untitled.swift
//  mirroringBooth
//
//  Created by 윤대현 on 1/15/26.
//

import SwiftUI

struct SpinningIndicatorView: View {
    let isActive: Bool

    @State private var isRotating = false

    init(isActive: Bool) {
        self.isActive = isActive
    }

    var body: some View {
        Image(systemName: "arrow.2.circlepath")
            .font(.title2)
            .rotationEffect(.degrees(-45))
            .rotationEffect(.degrees(isRotating ? 360 : 0))
            .animation(
                .linear(duration: 1).repeatForever(autoreverses: false),
                value: isRotating
            )
            .onAppear {
                if isActive {
                    isRotating = true
                }
            }
            .onChange(of: isActive) { _, newValue in
                isRotating = newValue
            }
    }
}
