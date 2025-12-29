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

    @State private var hevcFrameSender: HEVCFrameSender?
    @State private var hevcDecoder: HEVCDecoder?
    @State private var receivedPhotoData: Data?

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
                                    Text(sessionManager.connectionStateByDisplayName[peerID.displayName]?.rawValue ?? MPCSessionManager.ConnectionState.notConnected.rawValue)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()

                                let connections = sessionManager.connectionStateByDisplayName
                                if connections[peerID.displayName] == nil ||
                                    connections[peerID.displayName] == .notConnected {
                                    Button {
                                        selectedPeerID = peerID
                                        sessionManager.invite(peerID)
                                    } label: {
                                        Text("연결")
                                    }
                                } else if connections[peerID.displayName] == .connected {
                                    Button {
                                        if self.isStreaming {
                                            self.stopCapture()
                                        } else {
                                            self.startCapture()
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
                        self.stopCapture()
                        self.sessionManager.stop()
                        self.hevcDecoder = nil
                    } label: {
                        Text("Stop")
                    }
                    .disabled(!sessionManager.isBrowsing && !sessionManager.isAdvertising)
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Group {
                        Button {
                            self.startCapture()
                        } label: {
                            Image(systemName: "camera")
                                .font(.caption)
                        }

                        Button {
                            sessionManager.start(peerID)
                        } label: {
                            Text("Start")
                        }
                    }
                    .disabled(sessionManager.isBrowsing && sessionManager.isAdvertising)
                }
            }
            .fullScreenCover(isPresented: $isStreaming) {
                if self.hevcFrameSender != nil {
                    self.captureManager.stopCapture()
                }
            } content: {
                NavigationStack {
                    CameraPreview {
                        if self.hevcFrameSender != nil {
                            self.hevcFrameSender?.sendFrame()
                            return self.captureManager.latestCIImage
                        } else {
                            return self.receivedCIImage
                        }
                    } tapCameraButton: {
                        sessionManager.sendTapCameraSignal()
                    }
                    .navigationTitle("스트리밍")
                    .navigationBarTitleDisplayMode(.inline)
                    .navigationDestination(item: $receivedPhotoData) { photoData in
                        PhotoPreview(photoData)
                    }
                }
            }
            .onChange(of: sessionManager.receivedHEVCFrameData) { _, hevcFrameData in
                guard let hevcFrameData else { return }

                if self.hevcDecoder == nil {
                    let decoder = HEVCDecoder()

                    decoder.setDecodedImageHandler { ciImage in
                        self.receivedCIImage = ciImage
                        if self.isStreaming == false {
                            self.isStreaming = true
                        }
                    }
                    self.hevcDecoder = decoder
                }

                self.hevcDecoder?.decode(hevcFrameData)
            }
            .onChange(of: sessionManager.receivedPhotoHEICData) { _, photoData in
                self.receivedPhotoData = photoData
            }
            .onChange(of: sessionManager.receivedTapCameraSignal) { _, tapSignal in
                if tapSignal {
                    self.captureManager.capturePhoto { imageData in
                        if let data = imageData {
                            self.sessionManager.sendPhotoHEICData(data)
                        }
                    }
                }
                sessionManager.receivedTapCameraSignal = false
            }
        }
    }

    private func startCapture() {
        self.captureManager.startCapture()

        let frameSender = HEVCFrameSender(
            provider: { self.captureManager.latestCIImage },
            manager: self.sessionManager,
            bitrate: 2_500_000,
            targetFrameRate: 24
        )
        self.hevcFrameSender = frameSender

        self.isStreaming = true
    }

    private func stopCapture() {
        self.isStreaming = false
        self.hevcFrameSender?.invalidate()
        self.hevcFrameSender = nil
        self.hevcDecoder?.invalidate()
        self.captureManager.stopCapture()
    }
}
