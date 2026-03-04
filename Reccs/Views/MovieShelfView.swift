//
//  MovieShelfView.swift
//  Reccs
//
//  Created by Evan Gedrich Pintado on 3/3/26.
//

import SwiftUI

struct MovieShelfView: View {
    let shelfTitle: String
    let filteredMovies: [MovieEntry]
    @Environment(MovieStore.self) private var store
    @FocusState private var focusedID: String?
    @State private var scrollID: String?
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(shelfTitle)
                .font(.title3)
                .fontWeight(.bold)
                .padding(.leading, 80)
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 50) {
                    ForEach(filteredMovies) { movie in
                        MovieCard(movie: movie)
                            .id(movie.id)
                            .focused($focusedID, equals: movie.id)
                    }
                    Spacer()
                        .frame(width: 1500)
                }
                .scrollTargetLayout()
            }
            .scrollPosition(id: $scrollID, anchor: .leading)
            .scrollTargetBehavior(.viewAligned)
            .contentMargins(.horizontal, 80, for: .scrollContent)
            .onChange(of: focusedID) { _, newValue in
                scrollID = newValue
            }
            .scrollClipDisabled()
            .padding(.vertical, 10)
        }
        .onAppear {
            scrollID = store.films.first?.id
        }
    }
}
