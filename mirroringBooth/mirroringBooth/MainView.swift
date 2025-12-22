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
    @State private var cameraFrameSender: CameraFrameSender?
    @State private var isStreaming: Bool = false
    @State private var receivedCIImage: CIImage? = nil

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
                                    Button {
                                        if self.isStreaming == true {
                                            self.isStreaming = false
                                            if self.cameraFrameSender != nil {
                                                self.cameraFrameSender = nil
                                                self.captureManager.stopCapture()
                                            }
                                        } else {
                                            self.captureManager.startCapture()

                                            let sender = CameraFrameSender(
                                                provider: { self.captureManager.latestCIImage },
                                                manager: self.sessionManager,
                                                targetFps: 30
                                            )

                                            self.cameraFrameSender = sender
                                            self.isStreaming = true
                                        }
                                    } label: {
                                        Text(self.isStreaming ? "스트리밍 종료" : "스트리밍 시작")
                                    }
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

                        self.isStreaming = false
                        self.cameraFrameSender = nil
                        self.captureManager.stopCapture()
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
            }
            .fullScreenCover(isPresented: $isStreaming) {
                if self.cameraFrameSender != nil {
                    self.captureManager.stopCapture()
                }
            } content: {
                CameraPreview {
                    if self.cameraFrameSender != nil {
                        self.cameraFrameSender?.tickSend()
                        return self.captureManager.latestCIImage
                    } else {
                        return self.receivedCIImage
                    }
                }
            }
            .onChange(of: sessionManager.receivedMjpegFrameData) { _, mjpegFrameData in
                guard let mjpegFrameData: Data = mjpegFrameData else {
                    return
                }

                autoreleasepool {
                    guard let ciImage: CIImage = CIImage(data: mjpegFrameData) else {
                        self.receivedCIImage = nil
                        return
                    }

                    self.receivedCIImage = ciImage

                    if self.isStreaming == false {
                        self.isStreaming = true
                    }
                }
            }
        }
    }
}
