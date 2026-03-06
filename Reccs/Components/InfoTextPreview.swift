//
//  InfoTextPreview.swift
//  Reccs
//
//  Created by Evan Gedrich Pintado on 3/3/26.
//

import SwiftUI

struct InfoTextPreview: View {
    let text: String
    @Environment(\.isFocused) var isFocused // Native check for focus

    var body: some View {
        if let attributedText = try? AttributedString(markdown: text) {
            Text(attributedText)
                .font(.body)
                .lineLimit(3)
                .truncationMode(.tail)
                .foregroundColor(isFocused ? .black : .white.opacity(0.9))
                .scaleEffect(isFocused ? 1.02 : 1.0)
                .animation(.snappy, value: isFocused)
        } else {
            Text(text)
                .font(.body)
                .lineLimit(3)
                .truncationMode(.tail)
                .foregroundColor(isFocused ? .black : .white.opacity(0.9))
                .scaleEffect(isFocused ? 1.02 : 1.0)
                .animation(.snappy, value: isFocused)
        }
    }
}
