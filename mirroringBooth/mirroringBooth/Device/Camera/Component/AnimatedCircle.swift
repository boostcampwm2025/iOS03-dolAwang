//
//  AnimatedCircle.swift
//  mirroringBooth
//
//  Created by 윤대현 on 2026-01-13.
//

import SwiftUI

struct AnimatedCircle: View {
    let color: Color
    let animationTrigger: Bool
    
    var body: some View {
        ZStack {
            Circle()
                .foregroundStyle(color.opacity(0.3))
                .frame(width: 180, height: 180)

            Circle()
                .stroke(color, lineWidth: 3)
                .frame(width: 180, height: 180)
                .scaleEffect(animationTrigger ? 2 : 1)
                .opacity(animationTrigger ? 0 : 0.5)
                .animation(
                    .easeOut(duration: 1.4).repeatForever(autoreverses: false),
                    value: animationTrigger
                )

            Circle()
                .stroke(color, lineWidth: 3)
                .frame(width: 180, height: 180)
                .scaleEffect(animationTrigger ? 3 : 1)
                .opacity(animationTrigger ? 0.0 : 0.3)
                .animation(
                    .easeOut(duration: 1.8).repeatForever(autoreverses: false).delay(0.3),
                    value: animationTrigger
                )
        }
    }
}
