//
//  Advertiser+HeartBeater.swift
//  mirroringBooth
//
//  Created by Liam on 1/19/26.
//

import Foundation

extension Advertiser: HeartBeaterDelegate {
    func onHeartBeat(_ sender: HeartBeater) {
        switch advertiserType {
        case .mirroring:
            sendCommand(.heartBeat)
        case .remote:
            sendCommand(.remoteHeartBeat)
        }
    }

    func onTimeout(_ sender: HeartBeater) {
        DispatchQueue.main.async {
            self.onHeartBeatTimeout?()
        }
    }
}
