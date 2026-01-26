//
//  ResultView.swift
//  mirroringBooth
//
//  Created by 이상유 on 2026-01-13.
//

import SwiftUI
import UniformTypeIdentifiers

struct ResultView: View {
    @Environment(Router.self) var router: Router
    @Environment(RootStore.self) private var rootStore
    @State private var showHomeAlert: Bool = false
    @State private var showSavedToast: Bool = false
    @State private var toastMessage: String?
    @State private var showFileExporter: Bool = false
    @State private var document: ImageDocument?

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var renderedImage: UIImage?

    let resultPhoto: PhotoInformation

    var body: some View {
        VStack(spacing: 30) {

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
            if let result = renderedImage {
                Image(uiImage: result)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .scaleEffect(scale)
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                scale = lastScale * value
                            }
                            .onEnded { _ in
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
            }

            /// 버튼
            HStack {
                sharingButton(
                    icon: "square.and.arrow.down",
                    title: "갤러리 저장",
                    isContrast: false
                ) {
                    if let renderedImage {
                        if UIDevice.current.deviceType == "Mac" {
                            document = ImageDocument(image: renderedImage)
                            showFileExporter = true
                        } else {
                            PhotoSaver().saveImage(image: renderedImage) { result, _ in
                                if result {
                                    toastMessage = "갤러리에 저장되었습니다."
                                } else {
                                    toastMessage = "저장에 실패했습니다. 갤러리 접근 권한을 확인해주세요."
                                }
                                showSavedToast = true
                            }
                        }
                    }
                }

                sharingButton(
                    icon: "paperplane",
                    title: "Airdrop",
                    isContrast: true
                ) {
                    // TODO: Airdrop 액션
                }
                .hidden() // 공유 로직 추가 후 제거
            }

            Spacer()
        }
        .padding()
        .navigationBarBackButtonHidden()
        .backgroundStyle()
        .homeAlert(
            isPresented: $showHomeAlert,
            message: "홈으로 돌아가시겠습니까?"
        ) {
            router.reset()
            rootStore.send(.disconnect)
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                HomeButton(size: .headline) {
                    showHomeAlert = true
                }
            }
        }
        .task {
            renderedImage = PhotoComposer.render(with: resultPhoto)
        }
        .toast(
            isPresented: $showSavedToast,
            message: toastMessage ?? ""
        )
        .fileExporter(
            isPresented: $showFileExporter,
            document: document,
            contentType: .jpeg,
            defaultFilename: "MirroringBoothPhoto"
        ) { result in
            switch result {
            case .success:
                toastMessage = "파일이 저장되었습니다."
                showSavedToast = true
            case .failure:
                toastMessage = "저장에 실패했습니다."
                showSavedToast = true
            }
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
