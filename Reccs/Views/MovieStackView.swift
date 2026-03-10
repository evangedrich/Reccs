//
//  MovieStackView.swift
//  Reccs
//
//  Created by Evan Gedrich Pintado on 3/10/26.
//

import SwiftUI

struct MovieStackView: View {
    let movies: [MovieEntry]
    let columns: Int
    var body: some View {
        let rows = stride(from: 0, to: movies.count, by: columns).map { $0 }
        VStack(spacing: 50) {
            ForEach(rows, id: \.self) { rowIndex in
                HStack(spacing: 50) {
                    ForEach(rowIndex..<min(rowIndex + columns, movies.count), id: \.self) { index in
                        MovieCard(movie: movies[index])
                            .scaleEffect(1.0)
                    }
                }
            }
        }
        .padding(40)
    }
}
