//
//  Browser+HeartBeater.swift
//  mirroringBooth
//
//  Created by Liam on 1/19/26.
//

import Foundation

extension Browser: HeartBeaterDelegate {
    func onHeartBeat(_ sender: HeartBeater) {
        sendCommand(.heartBeat)
        if remoteHeartBeater != nil {
            sendRemoteCommand(.heartBeat)
        }
    }

    func onTimeout(_ sender: HeartBeater) {
        if sender === heartBeater {
            disconnect(useType: .mirroring)
            DispatchQueue.main.async {
                self.onHeartbeatTimeout?()
            }
        } else if sender === remoteHeartBeater {
            disconnect(useType: .remote)
            DispatchQueue.main.async {
                self.onRemoteHeartbeatTimeout?()
            }
        }
    }
}
