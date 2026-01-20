//
//  HeartBeaterDelegate.swift
//  mirroringBooth
//
//  Created by Liam on 1/19/26.
//

protocol HeartBeaterDelegate: AnyObject {
    func onHeartBeat()
    func onTimeout()
}
