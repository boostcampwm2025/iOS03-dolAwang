//
//  PhotoPreview.swift
//  mirroringBooth
//
//  Created by 최윤진 on 12/29/25.
//

import SwiftUI

struct PhotoPreview: View {
    private let heicData: Data

    init(_ heicData: Data) {
        self.heicData = heicData
    }

    var body: some View {
        if let uiImage = UIImage(data: heicData) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
                .navigationTitle("받은 사진")
                .navigationBarTitleDisplayMode(.inline)
        } else {
            Text("이미지를 불러올 수 없습니다")
                .foregroundColor(.secondary)
        }
    }
}
