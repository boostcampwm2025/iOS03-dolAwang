//
//  LocalAsyncImage.swift
//  mirroringBooth
//
//  Created by Liam on 1/14/26.
//

import SwiftUI

struct LocalAsyncImage: View {
    let url: URL
    @State private var image: Image?

    var body: some View {
        Group {
            if let image = image {
                image
                    .resizable()
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
            self.image = Image(systemName: "exclamationmark.triangle")
        }
    }
}
