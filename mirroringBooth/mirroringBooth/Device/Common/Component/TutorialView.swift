//
//  TutorialView.swift
//  mirroringBooth
//
//  Created by 이상유 on 2026-01-30.
//

import SwiftUI

struct TutorialView: View {
    @AppStorage("hasSeenTutorial") private var hasSeenTutorial: Bool = false
    @Binding var isPresented: Bool
    @State private var currentPage: Int = 0

    private let imageNames = ["tutorial1", "tutorial2", "tutorial3"]

    var body: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()

            VStack(spacing: 10) {
                TabView(selection: $currentPage) {
                    ForEach(0..<imageNames.count, id: \.self) { index in
                        Image(imageNames[index])
                            .resizable()
                            .aspectRatio(300/390, contentMode: .fit)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .padding(.horizontal, 10)
                            .tag(index)
                    }
                }
                .aspectRatio(300/450, contentMode: .fit)
                .frame(maxWidth: 600)
                .tabViewStyle(.page(indexDisplayMode: .always))

                Button {
                    dismiss()
                } label: {
                    Text(currentPage == imageNames.count - 1 ? "준비 됐어요!" : "건너뛰기")
                        .font(.headline)
                        .frame(maxWidth: 320)
                        .padding(.vertical, 14)
                        .foregroundStyle(.black)
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .opacity(currentPage == imageNames.count - 1 ? 1 : 0.5)
            }
            .padding(.horizontal, 30)
            .padding(.vertical, 40)
        }
    }

    private func dismiss() {
        hasSeenTutorial = true
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
