//
//  RootView.swift
//  mirroringBoothWatch
//
//  Created by 최윤진 on 1/7/26.
//

import SwiftUI

struct RootView: View {
    @State private var state: ConnectionState = .notConnected

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if state == .connected {
                connectedView
            } else {
                standbyView
            }
        }

    }

    private var connectedView: some View {
        VStack {
            Text("READY")
                .foregroundStyle(green500)
                .font(.caption.bold())
            Spacer()
            Button {

            } label: {
                ZStack {
                    Circle()
                        .stroke(darkGrayContainer, lineWidth: 0.5)
                    Image(systemName: "camera")
                        .font(.title2)
                        .foregroundStyle(darkGrayContainer)
                        .bold()
                }
                .frame(width: screenWidth / 2, height: screenWidth / 2)
                .background {
                    Circle()
                        .frame(width: screenWidth / 2 * 1.1, height: screenWidth / 2 * 1.1)
                }
            }
            .buttonStyle(.plain)
            Spacer()
        }
    }

    private var standbyView: some View {
        VStack(spacing: 6) {
            Group {
                Button {
                    state = .connecting

                } label: {
                    Image(systemName: "arrow.2.circlepath")
                        .font(.title2)
                        .rotationEffect(.degrees(-45))
                        .rotationEffect(state == .connecting ? .degrees(360) : .degrees(0))
                        .animation(
                            state == .connecting ? .linear(duration: 1).repeatForever(autoreverses: false): .linear,
                            value: state
                        )
                }
                .buttonStyle(.plain)
                Text("연결 대기 중...")
                    .fontWeight(.heavy)
            }
            .foregroundStyle(lightGrayontainer)
            Text("iPhone에서 연결해주세요")
                .font(.caption2)
                .foregroundStyle(darkGrayContainer)
        }
    }
}

// 1) Backgrounds
let lightGrayontainer = Color(#colorLiteral(red: 0.422652036, green: 0.4431175292, blue: 0.5056651235, alpha: 1)) // #6d7180
let darkGrayContainer = Color(#colorLiteral(red: 0.1215686275, green: 0.1607843137, blue: 0.2156862745, alpha: 1)) // #1f2937

let green500 = Color(#colorLiteral(red: 0.1333333333, green: 0.7725490196, blue: 0.368627451, alpha: 1)) // #22c55e
let green400 = Color(#colorLiteral(red: 0.2901960784, green: 0.8705882353, blue: 0.5019607843, alpha: 1)) // #4ade80

#Preview {
    RootView()
}
