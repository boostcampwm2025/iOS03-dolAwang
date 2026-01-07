//
//  BrowsingView.swift
//  mirroringBooth
//
//  Created by 이상유 on 2026-01-07.
//

import SwiftUI

struct BrowsingView: View {

    @Environment(Router.self) var router: Router
    @State private var browser = Browser()

    private enum Constants {
        enum Size {
            static let title: Font = .title.bold()
            static let iconCornerRadius: CGFloat = 15
        }

        enum Spacing {
            static let iconPadding: CGFloat = 10
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .foregroundStyle(Color("mirroringColor").opacity(0.3))
                .frame(width: 180, height: 180)

            Circle()
                .foregroundStyle(Color("mirroringColor").opacity(0.2))
                .frame(width: 260, height: 260)

            VStack {
                Image(systemName: "camera")
                    .padding(Constants.Spacing.iconPadding)
                    .font(Constants.Size.title)
                    .foregroundStyle(Color("mirroringColor"))
                    .background(Color("mirroringColor").opacity(0.2))
                    .clipShape(Capsule())

                Text("미러링 기기 찾는 중")
                    .font(.title2)
                    .bold()

                Text("화면을 공유할 기기를 선택해주세요.")
                    .font(.footnote)
                    .foregroundStyle(Color(.secondaryLabel))

                LazyVStack {
                    ScrollView {
                        deviceRow(
                            icon: Image(systemName: "iphone"),
                            name: "이상유의 iPhone",
                            type: "iPhone 15 pro max"
                        )
                        deviceRow(
                            icon: Image(systemName: "iphone"),
                            name: "이상유의 iPhone",
                            type: "iPhone 15 pro max"
                        )
                        deviceRow(
                            icon: Image(systemName: "iphone"),
                            name: "이상유의 iPhone",
                            type: "iPhone 15 pro max"
                        )
                    }
                }
                .padding(.horizontal)
                .frame(maxHeight: .infinity, alignment: .top)
                .padding(.bottom, 5)

                Button {
                    router.push(to: CameraRoute.connectionList)
                } label: {
                    Text("다음 단계")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(Color(.systemBackground))
                        .background(Color(.label))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

            }
            .padding()
        }
        .onAppear {
            browser.startSearching()
        }
        .onDisappear {
            browser.stopSearching()
        }
    }

    @ViewBuilder
    private func deviceRow(
        icon: Image,
        name: String,
        type: String
    ) -> some View {
        HStack {
            icon
                .font(.title)

            VStack(alignment: .leading) {
                Text(name)
                    .font(.headline.bold())
                Text(type)
                    .font(.footnote)
            }
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemBackground).opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    ContentView()
}
