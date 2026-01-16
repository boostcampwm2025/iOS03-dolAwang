//
//  WatchKitView+.swift
//  mirroringBoothWatch
//
//  Created by 최윤진 on 1/7/26.
//

import SwiftUI
import WatchKit

extension View {
    var screenWidth: CGFloat {
        WKInterfaceDevice.current().screenBounds.width
    }

    var screenHeight: CGFloat {
        WKInterfaceDevice.current().screenBounds.height
    }
}
