//
//  Browser+HeartBeater.swift
//  mirroringBooth
//
//  Created by Liam on 1/19/26.
//

import Foundation

extension Browser: HeartBeaterDelegate {
    func onHeartBeat() {
        sendCommand(.heartBeat)
    }

    func onTimeout() {
        DispatchQueue.main.async {
            self.onHeartbeatTimeout?()
        }
    }
}
