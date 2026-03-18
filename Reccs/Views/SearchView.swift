//
//  SearchView.swift
//  Reccs
//
//  Created by Evan Gedrich Pintado on 3/7/26.
//

import SwiftUI

struct SearchView: View {
    @State private var searchText = ""
    let store: MovieStore
    let columns = [
        GridItem(.fixed(300), spacing: 50),
        GridItem(.fixed(300), spacing: 50),
        GridItem(.fixed(300), spacing: 50),
        GridItem(.fixed(300), spacing: 50),
        GridItem(.fixed(300), spacing: 50)
    ];
    let columns2 = [
        GridItem(.fixed(480), spacing: 50),
        GridItem(.fixed(480), spacing: 50),
        GridItem(.fixed(480), spacing: 50)
    ];
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: searchText.isEmpty ? columns2 : columns, spacing: 50) {
                    if searchText.isEmpty {
                        ForEach(collections) { collection in
                            CollectionCard(collection: collection, searchText: $searchText)
                        }
                    } else {
                        ForEach(filteredMovies) { movie in
                            MovieCard(movie: movie)
                        }
                    }
                }
                .padding(.top, 20)
                .padding(.horizontal, 50)
            }
            .searchable(text: $searchText, prompt: "Search movies...")
            .navigationDestination(for: MovieEntry.self) { movie in
                MovieDetailView(movie: movie)
            }
        }
    }
    var filteredMovies: [MovieEntry] {
        guard !searchText.isEmpty else { return [] }
            
        return store.films.filter { movie in
            let regionMatch = movie.regionLabel.localizedCaseInsensitiveContains(searchText) ||
            (movie.id.hasPrefix("OC") && "Oceania".localizedCaseInsensitiveContains(searchText) ) ||
            (movie.id.hasPrefix("AF") && "Africa".localizedCaseInsensitiveContains(searchText)) ||
            (movie.id.hasPrefix("AM") && "America".localizedCaseInsensitiveContains(searchText)) ||
            ((movie.id.hasPrefix("EU") || movie.id.hasPrefix("AS")) && "Eurasia".localizedCaseInsensitiveContains(searchText))
            let titleMatch = movie.title.original.localizedCaseInsensitiveContains(searchText) ||
            [movie.title.transliteration, movie.title.translation]
                .compactMap { $0 }
                .contains { $0.localizedCaseInsensitiveContains(searchText) }
            let genreMatch = movie.genre.contains { $0.localizedCaseInsensitiveContains(searchText) }
            let tagMatch = movie.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            let groupMatch = [movie.group.people, movie.group.language, movie.group.country, movie.group.location]
                .compactMap { $0 }
                .contains { $0.localizedCaseInsensitiveContains(searchText) }
            let whichCollection = movie.id.substring(from: 4, to: 6)
            let collectionMatch = (whichCollection == "CFF" && "Cultural Feature Films".localizedCaseInsensitiveContains(searchText)) ||
                (whichCollection == "GFF" && "Globalized Feature Films".localizedCaseInsensitiveContains(searchText)) ||
                (whichCollection == "CSF" && "Cultural Short Films".localizedCaseInsensitiveContains(searchText))
            return regionMatch || titleMatch || genreMatch || tagMatch || groupMatch || collectionMatch
        }
    }
}
