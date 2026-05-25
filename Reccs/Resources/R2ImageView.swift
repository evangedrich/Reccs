//
//  R2ImageView.swift
//  Reccs
//
//  View for loading images from Cloudflare R2
//

import SwiftUI

struct R2ImageView: View {
    let url: URL?
    let fallbackImageName: String?
    let contentMode: ContentMode
    
    init(url: URL?, fallbackImageName: String? = nil, contentMode: ContentMode = .fill) {
        self.url = url
        self.fallbackImageName = fallbackImageName
        self.contentMode = contentMode
    }
    
    var body: some View {
        Group {
            if let url = url {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: contentMode)
                    case .failure:
                        fallbackContent
                    @unknown default:
                        fallbackContent
                    }
                }
            } else {
                fallbackContent
            }
        }
    }
    
    @ViewBuilder
    private var fallbackContent: some View {
        if let fallbackImageName = fallbackImageName {
            Image(fallbackImageName)
                .resizable()
                .aspectRatio(contentMode: contentMode)
        } else {
            Color.gray.opacity(0.3)
                .overlay {
                    Image(systemName: "photo")
                        .foregroundStyle(.secondary)
                }
        }
    }
}

#Preview {
    R2ImageView(
        url: URL(string: "https://example.com/image.jpg"),
        fallbackImageName: "placeholder",
        contentMode: .fit
    )
    .frame(width: 200, height: 300)
    .clipShape(RoundedRectangle(cornerRadius: 12))
}
