//
//  MongolianException.swift
//  Reccs
//
//  Created by Evan Gedrich Pintado on 3/14/26.
//

import SwiftUI
import Foundation

extension String {
    var isMongolian: Bool {
        let mongolianRange = CharacterSet(charactersIn: "\u{1800}"..."\u{18AF}")
        return self.rangeOfCharacter(from: mongolianRange) != nil
    }
}

struct MongolianText: View {
    let text: String
    var font: Font = .headline
    var columnWidth: CGFloat = 40 // The "thickness" of each vertical line
    var spacing: CGFloat = 0    // Gap between columns (words)

    private var words: [String] {
        text.split(separator: " ").map(String.init)
    }

    var body: some View {
        HStack(alignment: .top, spacing: spacing) {
            ForEach(words, id: \.self) { word in
                Text(word)
                    .font(font)
                    .fixedSize() // Prevents horizontal wrapping before rotation
                    .rotationEffect(.degrees(90), anchor: .topLeading)
                    .frame(width: columnWidth, alignment: .topLeading)
                    // The magic: Offset moves the text back into the narrow frame
                    .offset(x: columnWidth)
            }
        }
        .padding(.bottom, columnWidth+10)
    }
}



extension String {
    func substring(from: Int, to: Int) -> String? {
        guard from >= 0 && to < self.count && from <= to else { return nil }
        let start = self.index(self.startIndex, offsetBy: from)
        let end = self.index(self.startIndex, offsetBy: to)
        return String(self[start...end])
    }
}
