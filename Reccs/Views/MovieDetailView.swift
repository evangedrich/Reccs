//
//  MovieDetailView.swift
//  Reccs
//
//  Created by Evan Gedrich Pintado on 3/3/26.
//

import SwiftUI
import YouTubeKit
import AVFoundation

struct MovieDetailView: View {
    let movie: MovieEntry
    @State private var showInstallAlert = false
    @State private var showFullInfo = false
    @State private var preloadState = TrailerPreloadState() // Shared observable state
    @State private var trailerToPlay: TrailerData?
    @State private var showProviderList = false
    @State private var failedServiceName = ""
    @Namespace private var detailNamespace
    @FocusState private var focusedElement: FocusElement?
    
    var body: some View {
        ZStack {
            Color(hex: movie.color).ignoresSafeArea()
            HStack(spacing: 60) {
                VStack(alignment: .leading, spacing: 16) {
                    if movie.title.original.isMongolian {
                        MongolianText(
                            text: movie.title.original,
                            font: .system(size: 80, weight: .heavy),
                            columnWidth: 82
                        )
                    } else {
                        Text(movie.title.original)
                            .font(.system(size: 80, weight: .heavy))
                            .environment(\._lineHeightMultiple, 0.8)
                    }
                    
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
                                    let activity = NSUserActivity(activityType: NSUserActivityTypeBrowsingWeb)
                                    activity.webpageURL = url
                                    activity.becomeCurrent()

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
                            print("🎬 [DEBUG] Opening trailer - preloadedItem: \(preloadState.preloadedTrailerItem != nil), asset: \(preloadState.preloadingAsset != nil), task running: \(preloadState.preloadTask != nil && !(preloadState.preloadTask?.isCancelled ?? true))")
                            trailerToPlay = TrailerData(
                                videoURL: movie.trailer,
                                preloadState: preloadState
                            )
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "play.rectangle.fill")
                                Text("Play Trailer")
                            }
                        }
                        .focused($focusedElement, equals: .trailer)
                        .prefersDefaultFocus(movie.watch.first?.isEmpty ?? true, in: detailNamespace)
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
                    .padding(.bottom, -12)
                    .prefersDefaultFocus(true, in: detailNamespace)
                    
                    Button {
                        showFullInfo = true
                    } label: {
                        InfoTextPreview(text: movie.info)
                    }
                    .focused($focusedElement, equals: .info)
                    .buttonStyle(TransparentFocusStyle())
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
        .task {
            preloadState.preloadTask = Task {
                await preloadTrailer()
            }
        }
        .onDisappear {
            preloadState.preloadTask?.cancel()
        }
        .fullScreenCover(item: $trailerToPlay) { trailerData in
            TrailerPlayerView(
                videoURL: trailerData.videoURL,
                preloadState: trailerData.preloadState
            )
        }
        .alert(
            ["Kanopy","Klassiki","Mubi","Hoopla","Fawesome","Criterion"].contains(failedServiceName)
            ? "Cannot connect to \(failedServiceName)"
            : "\(failedServiceName) Not Installed",
            isPresented: $showInstallAlert
        ) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(
                ["Kanopy","Klassiki","Mubi","Hoopla","Fawesome","Criterion"].contains(failedServiceName)
                ? "Please install the \(failedServiceName) app, or if already installed, go to the app directly and search for this title."
                : "Please install the \(failedServiceName) app from the App Store to watch this film\(movie.watch.count>1 ? " or check other providers":"")."
            )
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
    
    func preloadTrailer() async {
        // 1. Small anti-scroll delay: Don't waste data if they are just passing through quickly
        try? await Task.sleep(nanoseconds: 100_000_000) // 100ms instead of 200ms
        
        guard let url = URL(string: movie.trailer) else { return }
        
        do {
            // 2. Extract streams (Remote API is faster and more reliable)
            let youtube = YouTube(url: url, methods: [.remote, .local])
            let streams = try await youtube.streams
            
            // 3. Try to get the highest quality by combining separate video + audio
            let bestVideo = streams.filter { stream in
                let codecString = stream.videoCodec.map { "\($0)".lowercased() } ?? ""
                return stream.audioCodec == nil && codecString.contains("avc1")
            }.highestResolutionStream()
            
            let bestAudio = streams.filter {
                $0.videoCodec == nil && $0.audioCodec != nil
            }.highestResolutionStream()
            
            if let vURL = bestVideo?.url, let aURL = bestAudio?.url {
                // HIGH QUALITY PATH: Separate video + audio streams (1080p capable)
                print("🎥 [PRELOAD] Using high-quality separate streams")
                
                let videoAsset = AVURLAsset(url: vURL)
                let audioAsset = AVURLAsset(url: aURL)
                
                // Store assets immediately so they start downloading
                await MainActor.run {
                    self.preloadState.preloadingVideoAsset = videoAsset
                    self.preloadState.preloadingAudioAsset = audioAsset
                    print("✅ [PRELOAD STARTED] Trailer assets for \(movie.title.original) are downloading...")
                }
                
                // Create composition and try to insert tracks
                let composition = AVMutableComposition()
                let compV = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
                let compA = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
                
                do {
                    // Load tracks first
                    async let vTracks = videoAsset.load(.tracks)
                    async let aTracks = audioAsset.load(.tracks)
                    
                    if let vTrack = try await vTracks.first,
                       let aTrack = try await aTracks.first {
                        // Load both time ranges to compare
                        let vTrackTimeRange = try await vTrack.load(.timeRange)
                        let aTrackTimeRange = try await aTrack.load(.timeRange)
                        
                        let vDuration = CMTimeGetSeconds(vTrackTimeRange.duration)
                        let aDuration = CMTimeGetSeconds(aTrackTimeRange.duration)
                        
                        print("📊 [PRELOAD] Video track: \(vDuration)s, Audio track: \(aDuration)s")
                        
                        // YouTube bug: Streams report double the actual duration
                        // Use half the duration for compositions to avoid playing duplicated content
                        let safeDuration = min(vDuration, aDuration) / 2.0
                        
                        print("✅ [PRELOAD] Using half duration (\(safeDuration)s) to avoid YouTube duplicate bug")
                        
                        let timeRange = CMTimeRange(start: .zero, duration: CMTime(seconds: safeDuration, preferredTimescale: 600))
                        
                        try compV?.insertTimeRange(timeRange, of: vTrack, at: .zero)
                        try compA?.insertTimeRange(timeRange, of: aTrack, at: .zero)
                        
                        print("✅ [PRELOAD] Composition created with duration: \(safeDuration)s")
                        
                        let item = AVPlayerItem(asset: composition)
                        item.preferredForwardBufferDuration = 1.0
                        
                        // Only set preloadingAsset AFTER tracks are successfully inserted
                        await MainActor.run {
                            self.preloadState.preloadingAsset = composition
                            self.preloadState.preloadedTrailerItem = item
                            print("✅ [PRELOAD READY] High-quality composition ready for \(movie.title.original)")
                        }
                    }
                } catch {
                    print("⚠️ [PRELOAD] Track insertion failed: \(error). Assets still available for playback.")
                }
            } else if let stream = streams.filter({ $0.isProgressive }).highestResolutionStream() {
                // FALLBACK: Progressive stream (typically 720p max)
                print("📹 [PRELOAD] Using progressive stream fallback")
                let asset = AVURLAsset(url: stream.url)
                let item = AVPlayerItem(asset: asset)
                item.preferredForwardBufferDuration = 1.0
                
                await MainActor.run {
                    self.preloadState.preloadingAsset = asset
                    self.preloadState.preloadedTrailerItem = item
                    print("✅ [PRELOAD READY] Trailer for \(movie.title.original) is buffered and ready for instant play.")
                }
            }
        } catch {
            print("Preload failed: \(error)")
        }
    }
}

struct TrailerData: Identifiable {
    let id = UUID()
    let videoURL: String
    let preloadState: TrailerPreloadState // Pass the shared state
}

@Observable
class TrailerPreloadState {
    var preloadingAsset: AVAsset?
    var preloadingVideoAsset: AVURLAsset?
    var preloadingAudioAsset: AVURLAsset?
    var preloadedTrailerItem: AVPlayerItem?
    var preloadTask: Task<Void, Never>?
}

enum FocusElement {
    case play, trailer, more, info
}



struct TransparentFocusStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        TransparentFocusView(configuration: configuration)
    }
}
struct TransparentFocusView: View {
    let configuration: ButtonStyle.Configuration
    @Environment(\.isFocused) private var isFocused: Bool // Detects tvOS focus

    var body: some View {
        configuration.label
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.white)
                    .opacity(isFocused ? 0.15 : 0.0)
            )
            .scaleEffect(isFocused ? 1.04 : 1.02) // Subtle lift effect
            .animation(.easeOut(duration: 0.2), value: isFocused)
    }
}

