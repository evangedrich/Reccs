//
//  FullInfoModal.swift
//  Reccs
//
//  Created by Evan Gedrich Pintado on 3/3/26.
//

import SwiftUI

struct FullInfoModal: View {
    let movie: MovieEntry
    @Binding var isPresented: Bool
    @Namespace private var modalNamespace

    var body: some View {
        ZStack {
            Rectangle().fill(.ultraThinMaterial).ignoresSafeArea()
            
            VStack(spacing: 30) {
                if movie.title.original.isMongolian {
                    MongolianText(
                        text: movie.title.original,
                        font: .title2,
                        columnWidth: 56
                    )
                } else {
                    Text(movie.title.original)
                        .font(.title2)
                        .bold()
                }
                
                ScrollView {
                    let processedMarkdown = movie.info.replacingOccurrences(of: "\n", with: "\n")
                        .replacingOccurrences(of: "<i>", with: "*")
                        .replacingOccurrences(of: "</i>", with: "*")
                        .replacingOccurrences(of: "<b>", with: "**")
                        .replacingOccurrences(of: "</b>", with: "**")
                    
                    if let attributedInfo = try? AttributedString(markdown: processedMarkdown, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)) {
                        Text(attributedInfo)
                            .font(.body)
                            .lineSpacing(0)
                            .multilineTextAlignment(.leading)
                    } else {
                        Text(movie.info)
                            .font(.body)
                            .lineSpacing(0)
                            .multilineTextAlignment(.leading)
                    }
                        
                    
                    if !movie.genre.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 15) {
                                ForEach(movie.genre, id: \.self) { genre in
                                    Text(genre.uppercased())
                                        .font(.caption)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 10)
                                        .background(
                                            Capsule()
                                                .fill(Color.white.opacity(0.15))
                                        )
                                }
                            }
                            .frame(minWidth: 1000)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 20)
                    }
                }
                .frame(maxWidth: 1000)
                
                Button("Close") {
                    isPresented = false
                }
                .prefersDefaultFocus(true, in: modalNamespace)
            }
            .padding(60)
            .focusScope(modalNamespace)
        }
    }
}
