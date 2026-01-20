//
//  LocalAsyncImage.swift
//  mirroringBooth
//
//  Created by Liam on 1/14/26.
//

import SwiftUI

struct LocalAsyncImage: View {
    let url: URL
    var slotAspect: CGFloat?
    @State private var image: Image?
    @State private var loadFailed = false

    var body: some View {
        Group {
            if loadFailed {
                Color.gray.opacity(0.3)
                    .overlay {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                    }
            } else if let image = image {
                if let slotAspect {
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                        .aspectRatio(slotAspect, contentMode: .fit)
                        .clipped()
                } else {
                    image
                        .resizable()
                }
            } else {
                Color.gray.opacity(0.3)
            }
        }
        .task {
            await loadImage()
        }
    }

    private func loadImage() async {
        guard image == nil else { return }

        let loadedImage = await Task.detached(priority: .userInitiated) {
            UIImage(contentsOfFile: url.path(percentEncoded: false))
        }.value

        if let loadedImage {
            withAnimation {
                self.image = Image(uiImage: loadedImage)
            }
        } else {
            self.loadFailed = true
        }
    }
}
