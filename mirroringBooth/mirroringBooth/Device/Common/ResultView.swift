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
    @State private var store: ResultStore

    let resultPhoto: PhotoInformation

    init(resultPhoto: PhotoInformation, store: ResultStore = ResultStore()) {
        self.resultPhoto = resultPhoto
        self.store = store
    }

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
            if let result = store.state.renderedImage {
                Image(uiImage: result)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .scaleEffect(store.state.scale)
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                store.send(.setScale(scale: store.state.lastScale * value))
                            }
                            .onEnded { _ in
                                store.send(.setLastScale(scale: store.state.scale))
                                if store.state.scale < 1.0 {
                                    withAnimation(.spring()) {
                                        store.send(.setScale(scale: 1.0))
                                        store.send(.setLastScale(scale: 1.0))
                                    }
                                } else if store.state.scale > 3.0 {
                                    withAnimation(.spring()) {
                                        store.send(.setScale(scale: 3.0))
                                        store.send(.setLastScale(scale: 3.0))
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
                    if let renderedImage = store.state.renderedImage {
                        if UIDevice.current.deviceType == "Mac" {
                            let document = ImageDocument(image: renderedImage)
                            store.send(.showFileExporter(true, document: document))
                        } else {
                            PhotoSaver().saveImage(image: renderedImage) { result, _ in
                                let toastMessage: String
                                if result {
                                    toastMessage = "갤러리에 저장되었습니다."
                                } else {
                                    toastMessage = "저장에 실패했습니다. 갤러리 접근 권한을 확인해주세요."
                                }
                                store.send(.showSavedToast(true, message: toastMessage))
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
            isPresented: Binding(
                get: { store.state.showHomeAlert },
                set: { store.send(.showHomeAlert($0)) }
            ),
            message: "홈으로 돌아가시겠습니까?"
        ) {
            router.reset()
            rootStore.send(.disconnect)
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                HomeButton(size: .headline) {
                    store.send(.showHomeAlert(true))
                }
            }
        }
        .task {
            store.send(
                .setRenderedImage(
                    image: PhotoComposer.render(with: resultPhoto) ?? UIImage()
                )
            )
        }
        .toast(
            isPresented: Binding(
                get: { store.state.showSavedToast },
                set: { store.send(.showSavedToast($0)) }
            ),
            message: store.state.toastMessage
        )
        .fileExporter(
            isPresented: Binding(
                get: { store.state.showFileExporter },
                set: { store.send(.showFileExporter($0)) }
            ),
            document: store.state.document ?? ImageDocument(image: UIImage()),
            contentType: .jpeg,
            defaultFilename: "MirroringBoothPhoto"
        ) { result in
            let toastMessage: String
            switch result {
            case .success:
                toastMessage = "파일이 저장되었습니다."
            case .failure:
                toastMessage = "저장에 실패했습니다."
            }
            store.send(.showSavedToast(true, message: toastMessage))
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
