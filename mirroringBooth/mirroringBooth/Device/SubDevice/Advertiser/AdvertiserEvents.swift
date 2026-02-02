//
//  AdvertiserEvents.swift
//  mirroringBooth
//
//  Created by Liam on 2/2/26.
//

import Foundation

enum AdvertiserEvents {
    case onConnected
}

enum FrameReceivingEvents {
    case streamDataReceived(Data)
}
