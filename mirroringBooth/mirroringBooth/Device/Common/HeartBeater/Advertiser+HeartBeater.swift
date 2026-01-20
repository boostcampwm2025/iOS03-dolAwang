//
//  Advertiser+HeartBeater.swift
//  mirroringBooth
//
//  Created by Liam on 1/19/26.
//

import Foundation

extension Advertiser: HeartBeaterDelegate {
    func onHeartBeat(_ sender: HeartBeater) {
        sendCommand(.heartBeat)
    }

    func onTimeout(_ sender: HeartBeater) {
        DispatchQueue.main.async {
            self.onHeartBeatTimeout?()
        }
    }
}
