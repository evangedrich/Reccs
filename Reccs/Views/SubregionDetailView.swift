//
//  SubregionDetailView.swift
//  Reccs
//
//  Created by Evan Gedrich Pintado on 3/10/26.
//

import SwiftUI

struct SubregionDetailView: View {
    @Environment(MovieStore.self) private var store
    @FocusState private var focusedElement: String?
    let id: String
    var body: some View {
        ZStack {
            Color(hex: "#181818").ignoresSafeArea()

            HStack(spacing: 100) {
                VStack(spacing: 40) {
                    VStack(alignment: .leading, spacing: 25) {
                        Text(SubregionNames[id] ?? id)
                            .font(.system(size: 50))
                            .fontWeight(.black)
                        Text(SubregionDescriptions[id] ?? "")
                            .font(.body)
                            .foregroundColor(.white.opacity(0.8))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    ZStack {
                        GlobeView(
                            textureImage: "globe-\(id)",
                            horizontalRotation: getHorizontalRotation(for: id),
                            verticalRotation: getVerticalRotation(for: id),
                            subregionID: id,
                            focusID: focusedElement
                        )
                    }
                    .frame(width: 550, height: 550)
//                    Spacer()
//                        .frame(height: 5)
                }
                .frame(width: 650)
                ScrollView(.vertical, showsIndicators: false) {
                    VStack {
                        Spacer(minLength: 0)
                        MovieStackView(
                            movies: store.films.filter { $0.id.hasPrefix(id) },
                            columns: 2,
                            focusedElement: $focusedElement
                        )
                        Spacer(minLength: 0)
                    }
                    .frame(minHeight: UIScreen.main.bounds.height)
                }
                .frame(maxWidth: 650)
            }
        }
        .navigationDestination(for: MovieEntry.self) { movie in
            MovieDetailView(movie: movie)
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .ignoresSafeArea()
    }
}

func getHorizontalRotation(for id: String) -> Double {
    if id.hasPrefix("AF") { return -20 }
    if ["AMCE", "AMCR"].contains(id) { return 85 }
    if ["AMWE", "AMNE", "AMSO"].contains(id) { return 64 }
    if id.hasPrefix("AM") { return 95 }
    if id=="ASSE" { return 250 }
    if id=="ASWE" { return 300 }
    if id.hasPrefix("AS") { return 270 }
    if id.hasPrefix("EU") { return 320 }
    if id=="OCMD" { return -40 }
    if ["OCAU", "OCML"].contains(id) { return 230 }
    if id=="OCPL" { return 160 }
    if id.hasPrefix("OC") { return 180 }
    return 0.0
}
func getVerticalRotation(for id: String) -> Double {
    if id.hasPrefix("AF") { return 0 }
    if ["AMNO", "AMEA", "AMSW", "AMNW", "AMIN"].contains(id) { return 40 }
    if ["AMWE", "AMNE", "AMSO"].contains(id) { return -10 }
    if id.hasPrefix("AM") { return 10 }
    if id=="ASSE" { return 0 }
    if id.hasPrefix("AS") { return 30 }
    if id.hasPrefix("EU") { return 40 }
    if ["OCAU", "OCML", "OCPL"].contains(id) { return -10 }
    if id.hasPrefix("OC") { return 0 }
    return 0.0
}
