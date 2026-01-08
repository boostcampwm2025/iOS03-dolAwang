//
//  WatchView.swift
//  mirroringBoothWatch
//
//  Created by 최윤진 on 1/7/26.
//

import SwiftUI

struct WatchView: View {
    @State var store = WatchViewStore(connectionManager: WatchConnectionManager())

    var body: some View {
        if store.state.isConnecting {
            WatchConnectionView(store: store)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay(alignment: .topLeading) {
                    Button {
                        store.send(.tapDisconnect)
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
        } else {
            Button {
                store.send(.tapConnect)
            } label: {
                connectionButton
            }
        }
    }

    private var connectionButton: some View {
        VStack(spacing: 10) {
            VStack(spacing: 5) {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.largeTitle.bold())
                
                Text("검색 가능 모드")
                    .font(.headline)
            }
            
            Text("다른 기기에서 검색 가능한 상태로 전환")
                .font(.footnote)
                .opacity(0.7)
        }
        .padding()
    }
}
