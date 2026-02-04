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
        if sender === mirroringHeartBeater {
            streamManager.yieldHeartbeatTimeoutToAll()
        } else if sender === remoteHeartBeater {
            streamManager.yieldRemoteHeartbeatTimeoutToAll()
        }
    }
}
