//
//  MovieCard.swift
//  Reccs
//
//  Created by Evan Gedrich Pintado on 3/3/26.
//

import SwiftUI

struct MovieCard: View {
    let movie: MovieEntry
    @Environment(MovieStore.self) private var movieStore
    
    var body: some View {
        let movieColor = Color(hex: movie.color)
        NavigationLink(value: movie) {
            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(movieColor)
                    .frame(width: 300, height: 400)
                
                // Use R2ImageView with fallback to local asset
                R2ImageView(
                    url: movieStore.getPosterURL(for: movie),
                    fallbackImageName: movie.id
                )
                .frame(width: 300, height: 400)
                .clipped()
                .cornerRadius(12)
                VStack(spacing: 6) {
                    if movie.title.original.isMongolian {
                        MongolianText(text: movie.title.original)
                    } else {
                        Text(movie.title.original)
                            .font(.headline)
                            .fontWeight(.regular)
                            .multilineTextAlignment(.center)
                            .environment(\._lineHeightMultiple, 0.8)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineLimit(3)
                    }
                    Text(movie.year)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .opacity(0.8)
                }
                .padding()
                .frame(width: 300)
                .background(
                    LinearGradient(colors: [movieColor, movieColor.opacity(0.7), .clear],
                                   startPoint: .bottom,
                                   endPoint: .top)
                    .cornerRadius(12)
                )
            }
        }
        .buttonStyle(.card)
    }
}
