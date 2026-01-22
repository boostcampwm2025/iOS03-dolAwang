//
//  HomeView.swift
//  mirroringBooth
//
//  Created by 이상유 on 2026-01-06.
//

import SwiftUI

struct HomeView: View {

    @Environment(Router.self) var router: Router
    private var accessManager: AccessManager = .init()
    let isiPhone: Bool = UIDevice.current.userInterfaceIdiom == .phone

    var body: some View {
        VStack(alignment: .leading) {
            MainHeaderView()

            Spacer()

            GeometryReader { geometry in
                if geometry.size.width > geometry.size.height {
                    HStack {
                        startButtons(isPortrait: false)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                } else {
                    VStack(spacing: 16) {
                        startButtons(isPortrait: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 30)
                }
            }

            Spacer()
        }
        .padding(.horizontal)
        .onAppear {
            accessManager.tryLocalNetwork()
        }
        .alert(accessManager.requiredAccess?.alertTitle ?? "",
               isPresented: Binding(
                get: { accessManager.requiredAccess != nil },
                set: { isPresented in
                    if !isPresented {
                        accessManager.requiredAccess = nil
                    }
                }
               )) {
                   Button("취소", role: .cancel) { }
                   Button("설정으로 이동") {
                       accessManager.openSettings()
                   }
               } message: {
                   Text(accessManager.requiredAccess?.alertMessage ?? "")
               }
               .backgroundStyle()
    }

    @ViewBuilder
    private func startButtons(isPortrait: Bool) -> some View {
        Button {
            accessManager.requestCameraAccess {
                accessManager.requestLocalNetworkAccess {
                    router.push(to: CameraRoute.browsing)
                }
            }
        } label: {
            selectionBox(
                forCamera: true,
                isPortrait: isPortrait
            )
        }
        .disabled(!isiPhone)

        Button {
            accessManager.requestLocalNetworkAccess {
                router.push(to: isiPhone ? CameraRoute.advertising : MirroringRoute.advertising)
            }
        } label: {
            selectionBox(
                forCamera: false,
                isPortrait: isPortrait
            )
        }
    }
}

extension HomeView {
    @ViewBuilder
    private func selectionBox(
        forCamera: Bool,
        isPortrait: Bool
    ) -> some View {
        let icons: [String] = forCamera ? ["camera"] : DeviceUseType.allCases.map { $0.icon }
        let title: String = forCamera ? "촬영 기기로 시작하기" : "미러링/리모트 기기로 시작하기"
        let description: String = forCamera ? "카메라를 통해 순간을 기록해보세요." : "Apple 기기로 순간을 공유해보세요."
        let colors: [Color] = forCamera ? [Color.main] : [Color.mirroring, Color.remote]
        let disable = !isiPhone && forCamera

        VStack(spacing: 20) {
            VStack {
                HStack {
                    ForEach(icons.indices, id: \.self) { index in
                        Image(systemName: icons[index])
                            .padding(10)
                            .font(.title.bold())
                            .foregroundStyle(colors[index])
                            .background(colors[index].opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 15))
                    }
                }

                Text(title)
                    .font(.title3.bold())
                    .foregroundStyle(Color(.label))
                    .padding(.top)

                Text(description)
                    .font(.footnote)
                    .foregroundStyle(Color(.secondaryLabel))
            }
            .opacity(disable ? 0.5 : 1)

            if disable {
                Label {
                    Text("촬영은 iPhone에서만 가능합니다!")
                } icon: {
                    Image(systemName: "exclamationmark.bubble")
                }
                .padding(.vertical, 5)
                .padding(.horizontal, 10)
                .foregroundStyle(.primary)
                .background(.gray.opacity(0.5))
                .font(.headline)
                .clipShape(RoundedRectangle(cornerRadius: 15))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .aspectRatio(isPortrait ? 4/3 : 3/4, contentMode: .fit)
        .background(.gray.opacity(0.02))
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .overlay {
            RoundedRectangle(cornerRadius: 15)
                .stroke(.gray.opacity(0.3), style: StrokeStyle(lineWidth: 1))
                .shadow(color: .black, radius: 15)
        }
        .padding(.horizontal)
    }
}
