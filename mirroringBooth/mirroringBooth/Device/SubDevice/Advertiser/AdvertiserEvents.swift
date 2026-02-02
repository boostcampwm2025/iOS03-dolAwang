//
//  AdvertiserEvents.swift
//  mirroringBooth
//
//  Created by Liam on 2/2/26.
//

import Foundation

enum AdvertiserEvents {
    case onConnected
    case navigateToSelectModeCommandCallBack(_ isRemoteEnable: Bool)
}

enum FrameReceivingEvents {
    case streamDataReceived(Data)
}
