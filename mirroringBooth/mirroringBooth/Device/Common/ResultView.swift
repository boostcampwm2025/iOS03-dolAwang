//
//  ResultView.swift
//  mirroringBooth
//
//  Created by 이상유 on 2026-01-13.
//

import SwiftUI

struct ResultView: View {
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            Color.background
                .ignoresSafeArea()

            VStack(spacing: 30) {
                /// 홈 버튼
                HomeButton(
                    size: .title3) {
                        // TODO: 홈으로 이동하는 액션
                    }
                    .frame(maxWidth: .infinity, alignment: .topLeading)

                Spacer()

                /// 완성 텍스트
                VStack(spacing: 10) {
                    Text("완성되었습니다!")
                        .font(.title.bold())
                    
                    Text("순간들이 기록되었습니다.")
                        .font(.caption)
                        .foregroundStyle(Color(.label).opacity(0.5))
                }

                /// 결과 이미지
                Image(systemName: "photo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .scaleEffect(scale)
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                scale = lastScale * value
                            }
                            .onEnded { value in
                                lastScale = scale
                                if scale < 1.0 {
                                    withAnimation(.spring()) {
                                        scale = 1.0
                                        lastScale = 1.0
                                    }
                                } else if scale > 3.0 {
                                    withAnimation(.spring()) {
                                        scale = 3.0
                                        lastScale = 3.0
                                    }
                                }
                            }
                    )
                
                /// 버튼
                HStack {
                    sharingButton(
                        icon: "square.and.arrow.down",
                        title: "갤러리 저장",
                        isContrast: false
                    ) {
                        // TODO: 갤러리 저장 액션
                    }
                    
                    sharingButton(
                        icon: "paperplane",
                        title: "Airdrop",
                        isContrast: true
                    ) {
                        // TODO: Airdrop 액션
                    }
                }
//                .hidden() // 저장 로직 추가 후 제거

                Spacer()
            }
            .padding()
            .navigationBarBackButtonHidden()
        }
    }

    private func sharingButton(
        icon: String,
        title: String,
        isContrast: Bool,
        _ action: @escaping () -> Void
    ) -> some View {
        Button {
            action()
        } label: {
            HStack {
                Image(systemName: icon)
                
                Text(title)
            }
            .padding(.vertical, 15)
            .padding(.horizontal, 25)
            .font(.headline)
            .fontWeight(.heavy)
            .foregroundStyle(isContrast ? Color(.systemBackground) : Color(.label))
            .background(isContrast ? Color(.label) : Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 30))
        }
    }
}
