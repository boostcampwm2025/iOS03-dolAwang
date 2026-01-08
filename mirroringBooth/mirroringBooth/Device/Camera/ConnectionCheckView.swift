//
//  ConnectionCheckView.swift
//  mirroringBooth
//
//  Created by 이상유 on 2026-01-07.
//

import SwiftUI

struct ConnectionCheckView: View {
    private let cameraDevice: String
    private let mirroringDevice: String
    private let remoteDevice: String?

    init(_ list: ConnectionList) {
        self.cameraDevice = list.cameraName
        self.mirroringDevice = list.mirroringName
        self.remoteDevice = list.remoteName
    }

    var body: some View {
        VStack(alignment: .leading) {
            // 1. 헤더
            VStack(alignment: .leading, spacing: 5) {
                Text("연동 확인")
                    .font(.title2.bold())

                Text("사용할 기기를 확인해주세요.")
                    .font(.caption)
                    .foregroundStyle(Color(.secondaryLabel))
            }
            .padding()

            Divider()

            // 2. 기기 목록
            ScrollView {
                VStack(spacing: 16) {
                    deviceCard(
                        title: "카메라",
                        icon: "camera",
                        name: cameraDevice,
                        color: Color("mainColor")
                    )

                    deviceCard(
                        title: "미러링",
                        icon: "display",
                        name: mirroringDevice,
                        color: Color("mirroringColor")
                    )

                    deviceCard(
                        title: "리모콘",
                        icon: "target",
                        name: remoteDevice,
                        color: Color("remoteColor")
                    )
                }
            }
            .padding()

            Spacer()

            // 3. 촬영 준비 버튼
            Button {
                // TODO: 카메라 프리뷰로 이동
            } label: {
                Text("촬영 준비하기")
                    .padding(14)
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(Color(.systemBackground))
                    .background(Color(.label))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

extension ConnectionCheckView {
    @ViewBuilder
    private func deviceCard(
        title: String,
        icon: String,
        name: String?,
        color: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .padding(8)
                    .foregroundStyle(color)
                    .background(color.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                Text(title)

                Spacer()

            }
            .font(.headline.bold())

            HStack {
                Text(name ?? "연결되지 않음")
                    .foregroundStyle(name == nil ? Color(.secondaryLabel) : Color(.label))
                    .bold()

                Spacer()

                if name != nil {
                    Image(systemName: "checkmark.circle")
                        .foregroundStyle(color)
                }
            }
            .font(.caption)
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .background(color.opacity(0.2))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(color.opacity(0.1), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(20)
        .background(Color(.secondarySystemBackground).opacity(0.6))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color(.label).opacity(0.06), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
}
