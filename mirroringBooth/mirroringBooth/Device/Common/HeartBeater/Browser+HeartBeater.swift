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
            browsingHeartbeatContinuation.yield(.heartbeatTimeout)
            connectionCheckHeartbeatContinuation.yield(.heartbeatTimeout)
            cameraPreviewHeartbeatContinuation.yield(.heartbeatTimeout)
        } else if sender === remoteHeartBeater {
            browsingHeartbeatContinuation.yield(.remoteHeartbeatTimeout)
            connectionCheckHeartbeatContinuation.yield(.remoteHeartbeatTimeout)
            cameraPreviewHeartbeatContinuation.yield(.remoteHeartbeatTimeout)
        }
    }
}
