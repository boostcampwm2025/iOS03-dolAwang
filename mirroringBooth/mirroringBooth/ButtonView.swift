import MultipeerConnectivity
import SwiftUI

struct ButtonView: View {
    @StateObject var multipeerManager = MultipeerManager()
    @State private var advertising: Bool = false
    @State private var showingAlert: Bool = false
    @State private var showSheet: Bool = false
    @State private var peerConnected: Bool = false
    
    var body: some View {
        NavigationStack {
            VStack {
                // 기기 검색 허용 버튼
                Toggle(isOn: $advertising) {
                    Text("기기 검색 허용")
                }
                .frame(width: 200, height: 50)
                .padding()
                .onChange(of: advertising) { _, newValue in
                    toggleAdvertising(on: newValue)
                }
                
                // 다른 기기 검색(화면 전환)
                Button(action: {
                    multipeerManager.startBrowsing()
                    showSheet = true
                }) {
                    Text("다른 기기 검색")
                        .frame(width: 150, height: 50)
                        .foregroundStyle(Color.black)
                        .background(Color.blue.opacity(0.3))
                        .cornerRadius(8)
                }
                .navigationDestination(isPresented: $showSheet) {
                    FoundPeersView(manager: multipeerManager)
                }
            }
            .alert(
                "연결 요청",
                isPresented: $showingAlert,
                presenting: multipeerManager.invitation,
            ) { invitation in
                Button("수락") {
                    invitation.handler(true, multipeerManager.session)
                    peerConnected = true
                }
                Button("거절", role: .cancel) {
                    invitation.handler(false, nil)
                }
            } message: { invitation in
                Text("\(invitation.peerID.displayName)에서 연결 요청을 받았습니다.")
            }
            .onChange(of: multipeerManager.invitation) {
                if multipeerManager.invitation != nil {
                    showingAlert = true
                }
            }
            .navigationDestination(isPresented: $peerConnected) {
                ReceivedCameraView(multipeerManager: multipeerManager)
            }
        }
    }
    
    private func toggleAdvertising(on: Bool) {
        if on {
            multipeerManager.startAdvertising()
        } else {
            multipeerManager.stopDiscovery()
        }
    }
}

#Preview {
    ButtonView()
}
