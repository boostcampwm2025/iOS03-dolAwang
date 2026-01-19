//
//  WatchConnectionView.swift
//  mirroringBooth
//
//  Created by 이상유 on 2026-01-09.
//

import SwiftUI

struct WatchConnectionView: View {
    let onClose: () -> Void
    @State private var store = WatchConnectionStore(connectionManager: WatchConnectionManager())
    @State private var spin = false

    var body: some View {
        Group {
            if store.state.connectionState == .connected {
                if store.state.isReadyToCapture {
                    if store.state.isCaptureCompleted {
                        CompletionView()
                    } else {
                        captureView
                    }
                } else {
                    connectionView
                }
            } else {
                watingView
                    .onAppear {
                        store.send(.startConnecting)
                    }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .topLeading) {
            Button {
                store.send(.disconnect)
                onClose()
            } label: {
                Image(systemName: "multiply")
                    .padding()
                    .background(
                        Circle()
                            .fill(.gray)
                    )
            }
            .buttonStyle(.plain)
        }
    }

    private var watingView: some View {
        VStack(spacing: 6) {
            Group {
                Image(systemName: "arrow.2.circlepath")
                    .font(.title2)
                    .rotationEffect(.degrees(-45))
                    .rotationEffect(.degrees(spin ? 360 : 0))
                    .animation(
                        .linear(duration: 1).repeatForever(autoreverses: false),
                        value: spin
                    )
                    .onAppear {
                        spin = true
                    }
                    .onDisappear {
                        spin = false
                    }

                Text("연결 대기 중...")
                    .fontWeight(.heavy)
            }
            .foregroundStyle(Color(.lightGray))

            Text("iPhone에서 연결해주세요")
                .font(.caption2.bold())
                .foregroundStyle(Color(.darkGray))
        }
    }

    private var connectionView: some View {
        VStack(spacing: 6) {
            Text("연결 완료!")
                .fontWeight(.heavy)

            Text("촬영 준비를 완료해주세요")
                .font(.caption2.bold())
                .foregroundStyle(Color(.darkGray))
        }
        .foregroundStyle(Color(.lightGray))
    }

    private var captureView: some View {
        VStack {
            Text("READY")
                .foregroundStyle(.green)
                .font(.caption.bold())
                .padding(.top, 10)
            Spacer()
            CaptureButton(width: screenWidth / 2) {
                store.send(.tapRequestCapture)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
