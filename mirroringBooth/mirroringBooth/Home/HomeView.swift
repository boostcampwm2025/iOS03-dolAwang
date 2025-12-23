//
//  HomeView.swift
//  mirroringBooth
//
//  Created by 이상유 on 2025-12-24.
//

import SwiftUI

struct HomeView: View {
    
    private var router: Router
    
    init(_ router: Router) {
        self.router = router
    }
    var body: some View {
        Button {
            router.push(to: .connection)
        } label: {
            Text("촬영하기")
                .font(.headline)
                .padding(5)
        }

    }
    
}

#Preview {
    HomeView(Router())
}
