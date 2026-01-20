//
//  Browser+HeartBeater.swift
//  mirroringBooth
//
//  Created by Liam on 1/19/26.
//

extension Browser: HeartBeaterDelegate {
    func onHeartBeat() {
        sendCommand(.heartBeat)
    }

    func onTimeout() {
        onHeartbeatTimeout?()
    }
}
