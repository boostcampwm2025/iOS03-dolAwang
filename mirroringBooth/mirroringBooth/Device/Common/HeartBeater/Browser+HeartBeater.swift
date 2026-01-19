//
//  Browser+HeartBeater.swift
//  mirroringBooth
//
//  Created by Liam on 1/19/26.
//

extension CameraDeviceSession: HeartBeaterDelegate {
    func onHeartBeat() {
        sendCommand(.heartBeat)
    }

    func onTimeout() {
        // TODO: on timeout action needed
    }
}
