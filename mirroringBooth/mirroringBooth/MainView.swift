//
//  MainView.swift
//  mirroringBooth
//
//  Created by 최윤진 on 12/20/25.
//

import MultipeerConnectivity
import SwiftUI

struct MainView: View {
    @AppStorage("peerID") private var peerID = UIDevice.current.name
    @State private var sessionManager = MPCSessionManager()
    private let captureManager = CameraCaptureManager()
    @State private var selectedPeerID: MCPeerID?
    @State private var showFullScreenCover = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Text("브라우징")
                        Spacer()
                        Text(sessionManager.isBrowsing ? "On" : "Off")
                            .foregroundColor(self.sessionManager.isBrowsing ? .green : .secondary)
                    }

                    HStack {
                        Text("광고")
                        Spacer()
                        Text(sessionManager.isAdvertising ? "On" : "Off")
                            .foregroundColor(self.sessionManager.isAdvertising ? .green : .secondary)
                    }

                    HStack {
                        Text("Peer ID")
                        TextField("기기명을 입력해주세요", text: $peerID)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: .infinity, alignment: .trailing)

                    }
                } header: {
                    Text("탐색/연결 상태")
                }

                Section {
                    if sessionManager.foundPeers.isEmpty {
                        Text(sessionManager.isBrowsing ? "근처 디바이스를 찾는 중입니다." : "Start를 눌러 탐색을 시작해 주세요.")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(sessionManager.foundPeers, id: \.self) { peerID in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(peerID.displayName)
                                    Text(sessionManager.connectionStateByPeerDisplayName[peerID.displayName]?.rawValue ?? MPCSessionManager.ConnectionState.notConnected.rawValue)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()

                                let connections = sessionManager.connectionStateByPeerDisplayName
                                if connections[peerID.displayName] == nil ||
                                    connections[peerID.displayName] == .notConnected {
                                    Button {
                                        selectedPeerID = peerID
                                        sessionManager.invite(peerID)
                                    } label: {
                                        Text("연결")
                                    }
                                    .buttonStyle(.borderless)
                                } else if connections[peerID.displayName] == .connected {
                                    .buttonStyle(.borderless)
                                    Button {
                                        sessionManager.disconnect(peerID)
                                    } label: {
                                        Text("연결 종료")
                                    }
                                    .buttonStyle(.borderless)
                                } else {
                                    Text("연결 중...")
                                        .foregroundColor(.accentColor)
                                }
                            }
                        }
                    }

                } header: {
                    Text("발견된 디바이스")
                }
            }
            .navigationTitle("Nearby Devices")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        selectedPeerID = nil
                        sessionManager.stop()
                    } label: {
                        Text("Stop")
                    }
                    .disabled(!sessionManager.isBrowsing && !sessionManager.isAdvertising)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        sessionManager.start(peerID)
                    } label: {
                        Text("Start")
                    }
                    .disabled(sessionManager.isBrowsing && sessionManager.isAdvertising)
                }

                ToolbarItem(placement: .automatic) {
                    Button {
                        self.captureManager.startCapture()
                        self.showFullScreenCover = true
                    } label: {
                        Text(self.showFullScreenCover ? "카메라 종료" : "카메라 보기")
                    }
                }
            }
            .fullScreenCover(isPresented: $showFullScreenCover) {
                self.captureManager.stopCapture()
            } content: {
                CameraPreview {
                    captureManager.latestCIImage
                }
            }
        }
    }
}
