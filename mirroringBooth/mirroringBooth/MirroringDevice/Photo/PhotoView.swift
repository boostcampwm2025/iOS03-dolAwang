//
//  PhotoView.swift
//  mirroringBooth
//
//  Created by 이상유 on 2025-12-29.
//

import SwiftUI

/// 촬영된 고화질 사진을 표시하는 화면
struct PhotoView: View {

    let photoData: Data
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)

            VStack {
                Spacer()

                // 고화질 사진 표시
                if let uiImage = UIImage(data: photoData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                Spacer()

                // 닫기 버튼
                Button {
                    dismiss()
                } label: {
                    Text("닫기")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.gray.opacity(0.8))
                        .cornerRadius(10)
                }
                .padding(.bottom, 30)
            }
        }
    }
}

#Preview {
    if let data = UIImage(systemName: "photo")?.pngData() {
        PhotoView(photoData: data)
    }
}
