//
//  ContentView.swift
//  Reccs
//
//  Created by Evan Gedrich Pintado on 2/13/26.
//

import SwiftUI

struct ContentView: View {
    @State private var store = MovieStore()
    @State private var selectedTab = 0
    @FocusState private var isHomeFocused: Bool
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                ScrollView {
                    VStack(spacing: 60) {
                        MovieShelfView(
                            shelfTitle: "American Cinema",
                            filteredMovies: store.films.filter { $0.id.hasPrefix("AM") }
                        )
                        MovieShelfView(
                            shelfTitle: "Eurasian Cinema",
                            filteredMovies: store.films.filter { $0.id.hasPrefix("AS") || $0.id.contains("EU") }
                        )
                        MovieShelfView(
                            shelfTitle: "African Cinema",
                            filteredMovies: store.films.filter { $0.id.hasPrefix("AF") }
                        )
                        MovieShelfView(
                            shelfTitle: "Oceanian Cinema",
                            filteredMovies: store.films.filter { $0.id.hasPrefix("OC") }
                        )
                    }
                    .padding(.top, 0)
                }
                .navigationDestination(for: MovieEntry.self) { movie in
                    MovieDetailView(movie: movie)
                }
                .defaultFocus($isHomeFocused, selectedTab == 0) 
                .focused($isHomeFocused)
            }
            .tabItem { Text("Home") }
            .tag(0)
            
            GeoschemeView()
                .tabItem { Text("Geoscheme") }
                .tag(1)
            
            SearchView(store: store)
                .tabItem { Text("Search") }
                .tag(2)
        }
    }
}

#Preview {
    ContentView()
}
