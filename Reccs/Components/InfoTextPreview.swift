//
//  InfoTextPreview.swift
//  Reccs
//
//  Created by Evan Gedrich Pintado on 3/3/26.
//

import SwiftUI

struct InfoTextPreview: View {
    let text: String

    var body: some View {
        if let attributedText = try? AttributedString(markdown: text) {
            Text(attributedText)
                .font(.body)
                .lineLimit(3)
                .truncationMode(.tail)
                .foregroundColor(.white.opacity(0.9))
        } else {
            Text(text)
                .font(.body)
                .lineLimit(3)
                .truncationMode(.tail)
                .foregroundColor(.white.opacity(0.9))
        }
    }
}
