//
//  MovieDetailView.swift
//  Reccs
//
//  Created by Evan Gedrich Pintado on 3/3/26.
//

import SwiftUI

struct MovieDetailView: View {
    let movie: MovieEntry
    @State private var showInstallAlert = false
    @State private var showFullInfo = false
    @State private var isPlayingTrailer = false
    @State private var showProviderList = false
    @State private var failedServiceName = ""
    @Namespace private var detailNamespace
    @FocusState private var focusedElement: FocusElement?
    
    var body: some View {
        ZStack {
            Color(hex: movie.color).ignoresSafeArea()
            HStack(spacing: 60) {
                VStack(alignment: .leading, spacing: 16) {
                    Text(movie.title.original)
                        .font(.system(size: 80, weight: .heavy))
                        .environment(\._lineHeightMultiple, 0.8)
                    
                    if movie.title.transliteration != nil || movie.title.translation != nil {
                        (
                            Text(movie.title.transliteration ?? "")
                            + Text((movie.title.transliteration != nil && movie.title.translation != nil) ? ", " : "")
                            + Text(movie.title.translation != nil ? "“\(movie.title.translation!)”" : "")
                        )
                        .font(.headline)
                    }
                    
                    HStack(spacing: 20) {
                        Text(movie.year)
                        Text("•")
                        Text("\(movie.runtime) min")
                        Text("•")
                        Text(movie.regionLabel)
                    }
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.8))
                    HStack(spacing: 35) {
                        if let people = movie.group.people, !people.isEmpty {
                            HStack(spacing: 6) {
                                Image(systemName: "person.2.fill")
                                Text(people)
                            }
                        }
                        if let lang = movie.group.language, !lang.isEmpty {
                            HStack(spacing: 6) {
                                Image(systemName: "quote.bubble.fill")
                                Text(lang)
                            }
                        }
                        if let country = movie.group.country, !country.isEmpty {
                            HStack(spacing: 6) {
                                Image(systemName: "globe")
                                Text(country)
                            }
                        } else if let location = movie.group.location, !location.isEmpty {
                            HStack(spacing: 6) {
                                Image(systemName: "mappin.and.ellipse")
                                Text(location)
                            }
                        }
                    }
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))

//                    ScrollView {
//                        Text(movie.info)
//                            .font(.body)
//                            .lineSpacing(0)
//                    }
//                    .frame(maxHeight: 300)
//                    .padding(.top, 10)
                    
                    HStack(spacing: 30) {
                        if let firstLink = movie.watch.first, !firstLink.isEmpty {
                            Button(action: {
                                if let url = movie.watchURL {
                                    UIApplication.shared.open(url, options: [:]) { success in
                                        if !success {
                                            self.failedServiceName = movie.watchServiceName
                                            self.showInstallAlert = true
                                        }
                                    }
                                }
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "play.fill")
                                    Text("Watch on \(movie.watchServiceName)")
                                }
                            }
                            .focused($focusedElement, equals: .play)
                            .prefersDefaultFocus(true, in: detailNamespace)
                        } else {
                            Button(action: { }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "play.slash")
                                    Text("Watch Unavailable")
                                }
                            }
                            .disabled(true)
                            .opacity(0.6)
                        }

                        Button(action: {
                            isPlayingTrailer = true
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "play.rectangle.fill")
                                Text("Play Trailer")
                            }
                        }
                        .focused($focusedElement, equals: .trailer)
                        .prefersDefaultFocus(movie.watch.first?.isEmpty ?? true, in: detailNamespace)
                        .fullScreenCover(isPresented: $isPlayingTrailer) {
                            TrailerPlayerView(videoURL: movie.trailer)
                        }
                        .contextMenu {
                            Button("Open in YouTube App") {
                                if let url = URL(string: movie.trailer) {
                                    UIApplication.shared.open(url)
                                }
                            }
                        }
                        
                        if movie.watch.count > 1 {
                            Button(action: {
                                showProviderList = true
                            }) {
                                Image(systemName: "rectangle.stack")
                                    .font(.system(size: 30, weight: .bold))
                                    .frame(width: 40, height: 40)
                            }
                            .focused($focusedElement, equals: .more)
                            .sheet(isPresented: $showProviderList) {
                                ProviderListView(
                                    movie: movie,
                                    isPresented: $showProviderList,
                                    showInstallAlert: $showInstallAlert,
                                    failedServiceName: $failedServiceName
                                )
                            }
                        }
                    }
                    .padding(.top, 20)
                    .prefersDefaultFocus(true, in: detailNamespace)
                    
                    Button {
                        showFullInfo = true
                    } label: {
                        InfoTextPreview(text: movie.info)
                    }
                    .focused($focusedElement, equals: .info)
                    .buttonStyle(.plain)
                    .padding(.top, 20)
                    .fullScreenCover(isPresented: $showFullInfo) {
                        FullInfoModal(movie: movie, isPresented: $showFullInfo)
                    }
                }
                .frame(maxWidth: 800)
                .focusScope(detailNamespace)
                
                Image(movie.id)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 450)
                    .cornerRadius(20)
            }
        }
        .alert("\(failedServiceName) Not Installed", isPresented: $showInstallAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Please install the \(failedServiceName) app from the App Store to watch this film\(movie.watch.count>1 ? " or check other providers":"").")
        }
        .onAppear {
            if let firstLink = movie.watch.first, !firstLink.isEmpty {
                focusedElement = .play
            } else {
                focusedElement = .trailer
            }
        }
        .toolbar(.hidden, for: .tabBar)
        .ignoresSafeArea(.container, edges: .top)
    }
}

enum FocusElement {
    case play, trailer, more, info
}
