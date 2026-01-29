//
//  TutorialView.swift
//  mirroringBooth
//
//  Created by 이상유 on 2026-01-30.
//

import SwiftUI

struct TutorialView: View {
    @Binding var isPresented: Bool
    @State private var currentPage: Int = 0

    private let imageNames = ["tutorial1", "tutorial2", "tutorial3"]

    var body: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()

            VStack(spacing: 10) {
                Button {
                    dismiss()
                } label: {
                    Text("건너뛰기")
                        .font(.subheadline.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .foregroundStyle(.background.opacity(0.8))
                        .background(.primary.opacity(0.8))
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                }
                .opacity(currentPage == imageNames.count - 1 ? 0 : 1)

                TabView(selection: $currentPage) {
                    ForEach(0..<imageNames.count, id: \.self) { index in
                        Image(imageNames[index])
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: 500)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .aspectRatio(300/390, contentMode: .fit)

                Button {
                    dismiss()
                } label: {
                    Text("준비 됐어요!")
                        .font(.headline)
                        .frame(maxWidth: 320)
                        .padding(.vertical, 14)
                        .foregroundStyle(.black)
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .opacity(currentPage == imageNames.count - 1 ? 1 : 0)
            }
            .padding(.horizontal, 30)
            .padding(.vertical, 40)
        }
    }

    private func dismiss() {
        UserDefaults.standard.set(true, forKey: "hasSeenTutorial")
        isPresented = false
    }
}

extension View {
    func tutorialOverlay(isPresented: Binding<Bool>) -> some View {
        self.overlay {
            if isPresented.wrappedValue {
                TutorialView(isPresented: isPresented)
                    .animation(.easeOut(duration: 0.5), value: isPresented.wrappedValue)
            }
        }
    }
}
