//
//  SubregionDetailView.swift
//  Reccs
//
//  Created by Evan Gedrich Pintado on 3/10/26.
//

import SwiftUI

struct SubregionDetailView: View {
    @State private var store = MovieStore()
    let id: String
    var body: some View {
        ZStack {
            Color(hex: "#181818").ignoresSafeArea()
            
            ScrollView(.vertical, showsIndicators: false) {
                ZStack {
                    Spacer()
                        .containerRelativeFrame(.vertical)
                    VStack(spacing: 40) {
                        Spacer()
                        Text(SubregionNames[id] ?? id)
                            .font(.system(size: 60))
                            .frame(height: 60)
                            .fontWeight(.heavy)
                        Text(SubregionDescriptions[id] ?? "")
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal, 175)
                        MovieStackView(
                            movies: store.films.filter { $0.id.hasPrefix(id) },
                            columns: 4
                        )
                        Spacer()
                    }
                }
            }
            //.ignoresSafeArea()
            .frame(width: 1350)
        }
        .navigationDestination(for: MovieEntry.self) { movie in
            MovieDetailView(movie: movie)
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .ignoresSafeArea(.container, edges: .top)
    }
}
