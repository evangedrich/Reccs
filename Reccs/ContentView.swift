//
//  ContentView.swift
//  Reccs
//
//  Created by Evan Gedrich Pintado on 2/13/26.
//

import SwiftUI

struct ContentView: View {
    @Environment(MovieStore.self) private var store
    @State private var selectedTab = 0
    @FocusState private var isHomeFocused: Bool
    @Environment(\.scenePhase) private var scenePhase
    @State private var shuffleSeed = DailyShuffle.todaySeed
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                ScrollView {
                    VStack(spacing: 60) {
                        MovieShelfView(
                            shelfTitle: "American Cinema",
                            filteredMovies: DailyShuffle.order(store.films.filter { $0.id.hasPrefix("AM") }, seed: shuffleSeed)
                        )
                        MovieShelfView(
                            shelfTitle: "Eurasian Cinema",
                            filteredMovies: DailyShuffle.order(store.films.filter { $0.id.hasPrefix("AS") || $0.id.contains("EU") }, seed: shuffleSeed)
                        )
                        MovieShelfView(
                            shelfTitle: "African Cinema",
                            filteredMovies: DailyShuffle.order(store.films.filter { $0.id.hasPrefix("AF") }, seed: shuffleSeed)
                        )
                        MovieShelfView(
                            shelfTitle: "Oceanian Cinema",
                            filteredMovies: DailyShuffle.order(store.films.filter { $0.id.hasPrefix("OC") }, seed: shuffleSeed)
                        )
                    }
                    .padding(.top, 0)
                    .id(shuffleSeed) // a new order starts each row back at its first card
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
        .onChange(of: scenePhase) { _, phase in
            // Only on returning to the app, so a row never reorders under someone browsing at midnight.
            if phase == .active {
                shuffleSeed = DailyShuffle.todaySeed
            }
        }
    }
}

#Preview {
    ContentView()
}
