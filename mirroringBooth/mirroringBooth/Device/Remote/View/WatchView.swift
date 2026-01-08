//
//  WatchView.swift
//  mirroringBoothWatch
//
//  Created by 최윤진 on 1/7/26.
//

import SwiftUI

struct WatchView: View {
    @State var store: WatchViewStore
    @State private var flag = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if store.state.connectionState == .connected {
                connectedView
                    .onAppear {
                        flag = false
                    }
            } else {
                standbyView
                    .onAppear {
                        flag = true
                    }
            }
        }
    }

    private var connectedView: some View {
        VStack {
            Text("READY")
                .foregroundStyle(green400)
                .font(.caption.bold())
                .padding(.top, 10)
            Spacer()
            CaptureButton(width: screenWidth) {
                store.send(.tapRequestCapture)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .topTrailing) {
            Button {
                store.send(.tapDisconnect)
            } label: {
                Image(systemName: "multiply")
                    .padding()
                    .background(
                        Circle()
                            .fill(darkGrayContainer)
                    )
            }
            .buttonStyle(.plain)
        }
    }

    private var standbyView: some View {
        VStack(spacing: 6) {
            Group {
                Image(systemName: "arrow.2.circlepath")
                    .font(.title2)
                    .rotationEffect(Angle(degrees: -45))
                    .rotationEffect(
                        flag ? Angle(degrees: 360) : Angle(degrees: 0)
                    )
                    .animation(
                        flag ? .linear(duration: 1).repeatForever(autoreverses: false) : nil,
                        value: flag
                    )

                Text("연결 대기 중...")
                    .fontWeight(.heavy)
            }
            .foregroundStyle(lightGrayontainer)
            Text("iPhone에서 연결해주세요")
                .font(.caption2)
                .foregroundStyle(darkGrayContainer)
        }
        .onAppear {
            store.send(.onAppear)
        }
    }
}

let lightGrayontainer = Color(#colorLiteral(red: 0.422652036, green: 0.4431175292, blue: 0.5056651235, alpha: 1)) // #6d7180
let darkGrayContainer = Color(#colorLiteral(red: 0.1215686275, green: 0.1607843137, blue: 0.2156862745, alpha: 1)) // #1f2937
let green400 = Color(#colorLiteral(red: 0.2901960784, green: 0.8705882353, blue: 0.5019607843, alpha: 1)) // #4ade80
