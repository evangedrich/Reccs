//
//  TrailerPlayerView.swift
//  Reccs
//
//  Created by Evan Gedrich Pintado on 3/3/26.
//

import SwiftUI
import AVKit
import YouTubeKit
import Combine

struct TrailerPlayerView: View {
    let videoURL: String
    @Environment(\.dismiss) var dismiss
    @State private var player = AVPlayer()
    
    @State private var isBuffering = true
    @State private var showLongLoadingMessage = false
    @State private var cancellables = Set<AnyCancellable>()

    var body: some View {
        ZStack {
            VideoPlayer(player: player)
                .ignoresSafeArea()
            
            // Overlay for long loading
            if isBuffering && showLongLoadingMessage {
                Text("Buffering High-Quality Stream...")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .transition(.opacity)
                    .offset(y: -100)
            }
        }
        .onAppear {
            loadVideo()
            startLoadingTimer()
        }
        // Detect when video starts to hide the message
        .onReceive(player.publisher(for: \.timeControlStatus)) { status in
            if status == .playing {
                withAnimation(.easeInOut(duration: 0.5)) {
                    isBuffering = false
                }
            }
        }
    }
    
    func startLoadingTimer() {
        // Only show the message if it takes longer than 5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            if isBuffering {
                withAnimation {
                    showLongLoadingMessage = true
                }
            }
        }
    }
    
    func loadVideo() {
        guard let url = URL(string: videoURL) else { dismiss(); return }
        
        Task {
            // 1. We keep a reference for the composition
            var finalComposition: AVMutableComposition?
            
            do {
                // 2. Use both local and remote methods for the best chance of success
                let youtube = YouTube(url: url, methods: [.local, .remote])
                let streams = try await youtube.streams
                
                // 3. TRY HIGH QUALITY: Filter for 1080p AVC (h.264)
                let bestVideo = streams.filter { stream in
                    guard let vCodec = stream.videoCodec else { return false }
                    let codecString = "\(vCodec)".lowercased()
                    return stream.audioCodec == nil &&
                           codecString.contains("avc1") &&
                           !codecString.contains("vp9") &&
                           !codecString.contains("av01")
                }.highestResolutionStream()
                
                let bestAudio = streams.filter {
                    $0.videoCodec == nil && $0.audioCodec != nil
                }.highestResolutionStream()

                // 4. If we found both, try to Mux them
                if let vURL = bestVideo?.url, let aURL = bestAudio?.url {
                    let composition = AVMutableComposition()
                    let videoAsset = AVURLAsset(url: vURL)
                    let audioAsset = AVURLAsset(url: aURL)
                    
                    let vTracks = try await videoAsset.loadTracks(withMediaType: .video)
                    let aTracks = try await audioAsset.loadTracks(withMediaType: .audio)
                    let duration = try await videoAsset.load(.duration)
                    
                    if let vTrack = vTracks.first, let aTrack = aTracks.first {
                        let transform = try await vTrack.load(.preferredTransform)
                        let compV = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
                        let compA = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
                        
                        try compV?.insertTimeRange(CMTimeRange(start: .zero, duration: duration), of: vTrack, at: .zero)
                        try compA?.insertTimeRange(CMTimeRange(start: .zero, duration: duration), of: aTrack, at: .zero)
                        compV?.preferredTransform = transform
                        
                        finalComposition = composition
                    }
                }
                
                await MainActor.run {
                    let newPlayer: AVPlayer
                    
                    if let composition = finalComposition {
                        // 5. SUCCESS: Play Muxed High Quality
                        newPlayer = AVPlayer(playerItem: AVPlayerItem(asset: composition))
                    } else if let fallback = streams.filter({ $0.isProgressive }).highestResolutionStream() {
                        // 6. CAUTIOUS FALLBACK: Play 720p if Muxing failed
                        newPlayer = AVPlayer(url: fallback.url)
                    } else {
                        dismiss()
                        return
                    }
                    
                    newPlayer.automaticallyWaitsToMinimizeStalling = false
                    newPlayer.publisher(for: \.status)
                        .filter { $0 == .readyToPlay }
                        .first()
                        .sink { _ in newPlayer.play() }
                        .store(in: &cancellables)
                    
                    self.player = newPlayer
                }
            } catch {
                // 7. FINAL SAFETY: If everything fails, dismiss
                print("Trailer Error: \(error)")
                await MainActor.run { dismiss() }
            }
        }
    }
}
