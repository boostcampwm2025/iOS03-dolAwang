//
//  BrowserView.swift
//  mirroringBooth
//
//  Created by 이상유 on 2025-12-24.
//

import SwiftUI

struct BrowserView: View {
    
    private var router: Router
    
    init(_ router: Router) {
        self.router = router
    }
    
    var body: some View {
        Button {
            router.pop()
        } label: {
            Text("뒤로가기")
                .font(.headline)
                .padding(5)
        }
    }
}

#Preview {
    BrowserView(Router())
}
