//
//  CaptureResultView.swift
//  mirroringBooth
//
//  Created by Liam on 1/7/26.
//

import SwiftUI

struct CaptureResultView: View {
    @State var store: CaptureResultStore

    var body: some View {
        ZStack {
            Color.background
                .ignoresSafeArea()

            GeometryReader { geometry in
                if geometry.size.height > geometry.size.width {
                    portraitLayout(with: geometry)
                } else {
                    landscapeLayout(with: geometry)
                }
            }
        }
        .onAppear {
            store.send(.onAppear)
        }
    }
}

// MARK: - Components

private extension CaptureResultView {
    /// 세로 레이아웃
    func portraitLayout(with geometry: GeometryProxy) -> some View {
        VStack {
            photoGridView

            Divider()
                .background(.main)

            HStack {
                editingPanel(isPortrait: true)
            }
            // 화면 표시 비율
            .frame(height: geometry.size.height * 0.5)
        }
    }

    /// 가로 레이아웃
    func landscapeLayout(with geometry: GeometryProxy) -> some View {
        HStack {
            photoGridView

            Divider()
                .background(.main)

            VStack {
                editingPanel(isPortrait: false)
            }
            // 화면 표시 비율
            .frame(width: geometry.size.width * 0.33)
        }
    }

    /// 편집 패널 (결과 프리뷰 + 프레임/레이아웃 선택 뷰)
    @ViewBuilder
    func editingPanel(isPortrait: Bool) -> some View {
        if store.state.layoutRowCount != 0 && store.state.layoutColumnCount != 0 {
            // 임시로 적용해둔 상태, State 연결 필요
            PhotoFramePreview(
                layout: .fourByOne,
                frame: UIImage(named: "testFramee")!,
                photos: [
                    UIImage(named: "test")!,
                    UIImage(named: "test")!,
                    UIImage(named: "test")!,
                    UIImage(named: "test")!
                ]
            )
            .padding(12)
            .padding(isPortrait ? .leading : .trailing, 7)
        }

        Divider()
            .background(.main)

        FrameSelectionView(store: store)
    }

    /// 촬영된 사진 그리드 뷰
    var photoGridView: some View {
        VStack(alignment: .leading) {
            // 제목 및 Description
            Text("사진 선택 (\(store.state.currentSelectionCount)/\(store.state.maxSelection))")
                .font(.title.bold())
                .foregroundColor(.primary)

            Text("촬영된 10장의 사진 중 마음에 드는 사진을 골라주세요.")
                .font(.subheadline)
                .foregroundColor(.gray)
                .padding(.bottom, 16)

            // 사진 표시 구역
            GeometryReader { geometry in
                PhotoGrid(store: store, geometry: geometry)
            }
        }
        .padding()
    }
}
