//
//  HomeView.swift
//  mirroringBooth
//
//  Created by 이상유 on 2026-01-06.
//

import SwiftUI

struct HomeView: View {

    @Environment(Router.self) var router: Router

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
        .backgroundStyle()
    }

    @ViewBuilder
    private func startButtons(isPortrait: Bool) -> some View {
        Button {
            router.push(to: CameraRoute.browsing)
        } label: {
            selectionBox(
                icons: ["camera"],
                title: "촬영 기기로 시작하기",
                description: "카메라를 통해 순간을 기록해보세요.",
                colors: [Color.main],
                isPortrait: isPortrait
            )
        }

        Button {
            router.push(to: CameraRoute.advertising)
        } label: {
            selectionBox(
                icons: ["display", "target"],
                title: "미러링/리모트 기기로 시작하기",
                description: "Apple 기기로 순간을 공유해보세요.",
                colors: [Color.mirroring, Color.remote],
                isPortrait: isPortrait
            )
        }
    }
}

extension HomeView {
    @ViewBuilder
    private func selectionBox(
        icons: [String],
        title: String,
        description: String,
        colors: [Color],
        isPortrait: Bool
    ) -> some View {
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .aspectRatio(isPortrait ? 4/3 : 3/4, contentMode: .fit)
        .background(Color(.secondarySystemBackground).opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .overlay {
            RoundedRectangle(cornerRadius: 15)
                .stroke(.gray.opacity(0.3), style: StrokeStyle(lineWidth: 1))
                .shadow(color: .black, radius: 15)
        }
        .padding(.horizontal)
    }
}
