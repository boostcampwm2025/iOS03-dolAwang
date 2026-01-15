//
//  View+Background.swift
//  mirroringBooth
//
//  Created by 이상유 on 2026-01-15.
//

import SwiftUI

extension View {
    func backgroundStyle() -> some View {
        self.background(
            Color.background
                .ignoresSafeArea()
        )
    }
}
