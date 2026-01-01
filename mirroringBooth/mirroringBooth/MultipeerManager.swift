//
//  MultipeerManager.swift
//  mirroringBooth
//
//  Created by Liam on 12/25/25.
//

import Combine
import MultipeerConnectivity
import OSLog

final class MultipeerManager: NSObject, ObservableObject {
    let session: MCSession
    var advertiser: MultipeerAdvertiser?
    var browser: MultipeerBrowser?
    
    @Published var mainPeer: MCPeerID?
    @Published var secondaryPeer: MCPeerID?
    @Published var sessionState: MCSessionState = .notConnected
    @Published var invitation: MultipeerInvitation? = nil
    
    private let decoder = H264Decoder()
    @Published var receivedImage: CGImage? = nil
    @Published var capturedPHoto: UIImage? = nil
    
    override init() {
        let peerID = MCPeerID(displayName: UIDevice.current.name)
        self.session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        super.init()
        self.session.delegate = self
        decoder.delegate = self
    }
    
    /// ButtonView 같은 외부 View가 Delegate가 되어 초대장을 처리하도록 설정
    func startAdvertising() {
        if advertiser == nil {
            advertiser = MultipeerAdvertiser(session: session)
        }
        advertiser?.configure(delegate: self)
    }
    
    func startBrowsing() {
        if browser == nil {
            browser = MultipeerBrowser(session: session)
        }
    }
    
    func stopDiscovery() {
        advertiser?.stop()
        browser?.stop()
    }
    
    func stopSession() {
        session.disconnect()
        advertiser = nil
        browser = nil
    }
    
    func sendData(_ data: Data, type: UInt8) { // video=0, image=1
        guard let mainPeer else { return }
        do {
            var packet = Data()
            packet.append(type)
            packet.append(data)
            try session.send(
                packet,
                toPeers: [mainPeer],
                with: type == 0 ? .unreliable : .reliable
            )
        } catch {
            Logger.multipeerManager.debug("❌ 데이터 전송 실패: \(error)")
        }
    }
    
    func clearPhoto() {
        capturedPHoto = nil
    }
}

extension MultipeerManager: AcceptInvitationDelegate {
    func didReceiveInvitation(session: MCSession, didReceiveInvitationFromPeer peerID: MCPeerID, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        DispatchQueue.main.async {
            self.invitation = MultipeerInvitation(
                peerID: peerID,
                handler: invitationHandler
            )
        }
    }
}

extension MultipeerManager: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            self.sessionState = state
            
            switch state {
            case .connected:
                Logger.multipeerManager.debug("✅ 연결 성공! 상대방: \(peerID.displayName)")
                if let mainPeer = self.mainPeer {
                    self.secondaryPeer = peerID
                } else {
                    self.mainPeer = peerID
                }
                
            case .connecting:
                Logger.multipeerManager.debug("🟡 연결 시도 중...")
                
            case .notConnected:
                Logger.multipeerManager.debug("🔴 연결 끊김")
                if self.mainPeer != nil, peerID == self.mainPeer {
                    self.mainPeer = nil
                } else if self.secondaryPeer != nil, peerID == self.secondaryPeer {
                    self.secondaryPeer = nil
                }
                
            @unknown default:
                break
            }
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        guard data.count > 1 else { return }
        let type = data[0]
        let payload = Data(data.dropFirst())
        
        if type == 0 {
            decoder.decode(payload: payload)
        } else if type == 1 {
            if let image = UIImage(data: payload) {
                DispatchQueue.main.async {
                    self.capturedPHoto = image
                }
            }
        }
    }
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}

extension MultipeerManager: H264DecoderDelegate {
    func decoder(_ decoder: H264Decoder, didDecode imageBuffer: CVImageBuffer) {
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        let context = CIContext()
        
        if let cgImage = context.createCGImage(ciImage, from: ciImage.extent) {
            DispatchQueue.main.async {
                self.receivedImage = cgImage
            }
        }
    }
}
