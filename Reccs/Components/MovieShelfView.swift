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
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(shelfTitle)
                .font(.title3)
                .fontWeight(.bold)
                .padding(.leading, 80)
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 50) {
                        if store.isLoading && filteredMovies.isEmpty {
                            // Show loading skeletons
                            ForEach(0..<5, id: \.self) { index in
                                MovieCardSkeleton()
                            }
                        } else {
                            // Show actual movies
                            ForEach(filteredMovies) { movie in
                                MovieCard(movie: movie)
                                    .id(movie.id)
                                    .focused($focusedID, equals: movie.id)
                                    .accessibilityIdentifier("shelf-card-\(movie.id)")
                            }
                        }
                        Spacer()
                            .frame(width: 1500)
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.viewAligned)
                .contentMargins(.horizontal, 80, for: .scrollContent)
                .onChange(of: focusedID) { _, newValue in
                    guard let newValue else { return }
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                        proxy.scrollTo(newValue, anchor: .leading)
                    }
                }
                .scrollClipDisabled()
                .padding(.vertical, 10)
            }
        }
    }
}
