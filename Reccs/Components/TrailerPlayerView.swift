//
//  TrailerPlayerView.swift
//  Reccs
//
//  Created by Evan Gedrich Pintado on 3/3/26.
//

import SwiftUI
import AVKit
import YouTubeKit

struct TrailerPlayerView: View {
    let videoURL: String
    let preloadState: TrailerPreloadState // Receive the shared observable state
    @Environment(\.dismiss) var dismiss
    @State private var player = AVPlayer()
    
    @State private var isBuffering = true
    @State private var showLongLoadingMessage = false
    @State private var hasReachedEnd = false
    @State private var observerStoppedCheckTimer: Timer?

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
            print("📺 [INIT] TrailerPlayerView received - composition: \(preloadState.preloadingAsset != nil), video/audio: \(preloadState.preloadingVideoAsset != nil && preloadState.preloadingAudioAsset != nil), task: \(preloadState.preloadTask != nil)")
            
            // 1. Configure the player for speed immediately
            player.automaticallyWaitsToMinimizeStalling = false

            if let composition = preloadState.preloadingAsset as? AVMutableComposition {
                // SCENARIO 1: Composition is ready with tracks inserted
                print("🚀 [SUCCESS] Using fully preloaded composition for instant play")
                
                let item = AVPlayerItem(asset: composition)
                item.preferredForwardBufferDuration = 1.0
                player.replaceCurrentItem(with: item)
                player.playImmediately(atRate: 1.0)
                
                startLoadingTimer()
            } else if let videoAsset = preloadState.preloadingVideoAsset, let audioAsset = preloadState.preloadingAudioAsset {
                // SCENARIO 2: Assets are downloading but composition not ready yet
                // Continue the composition process that was started in preload
                print("⏳ [CONTINUE] Composition in progress, creating player item from downloading assets...")
                
                Task {
                    await createCompositionAndPlay(videoAsset: videoAsset, audioAsset: audioAsset)
                }
                
                startLoadingTimer()
            } else if let progressiveAsset = preloadState.preloadingAsset {
                // SCENARIO 3: Progressive stream (already complete)
                print("🚀 [SUCCESS] Using progressive stream for instant play")
                
                let item = AVPlayerItem(asset: progressiveAsset)
                item.preferredForwardBufferDuration = 1.0
                player.replaceCurrentItem(with: item)
                player.playImmediately(atRate: 1.0)
                
                startLoadingTimer()
            } else if let task = preloadState.preloadTask {
                // SCENARIO 4: Preload task is still running (probably extracting streams)
                // Wait for it to complete instead of starting from scratch!
                print("⏰ [WAIT] Preload task in progress, waiting for it to complete...")
                
                Task {
                    // Wait for the preload task to finish
                    await task.value
                    
                    // After preload completes, check the LIVE state (not captured copies!)
                    await MainActor.run {
                        if let composition = preloadState.preloadingAsset as? AVMutableComposition {
                            print("🎉 [READY] Preload completed! Using composition.")
                            let item = AVPlayerItem(asset: composition)
                            item.preferredForwardBufferDuration = 1.0
                            player.replaceCurrentItem(with: item)
                            player.playImmediately(atRate: 1.0)
                        } else if let videoAsset = preloadState.preloadingVideoAsset, let audioAsset = preloadState.preloadingAudioAsset {
                            print("🎉 [READY] Preload completed! Building composition from assets.")
                            Task {
                                await createCompositionAndPlay(videoAsset: videoAsset, audioAsset: audioAsset)
                            }
                        } else if let progressiveAsset = preloadState.preloadingAsset {
                            print("🎉 [READY] Preload completed! Using progressive stream.")
                            let item = AVPlayerItem(asset: progressiveAsset)
                            item.preferredForwardBufferDuration = 1.0
                            player.replaceCurrentItem(with: item)
                            player.playImmediately(atRate: 1.0)
                        } else {
                            // Preload failed, fall back to fresh load
                            print("⚠️ [FALLBACK] Preload task completed but no assets available.")
                            loadVideo()
                        }
                    }
                }
                
                startLoadingTimer()
            } else {
                // SCENARIO 5: No preload exists at all (user clicked immediately before preload started)
                print("⚠️ [FALLBACK] No preload found, starting fresh load.")
                
                loadVideo()
                startLoadingTimer()
            }
            
            // Set up end-of-video detection
            setupEndDetection()
        }
        .onDisappear {
            player.pause()
            observerStoppedCheckTimer?.invalidate()
            NotificationCenter.default.removeObserver(self)
        }
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
    
    func createCompositionAndPlay(videoAsset: AVURLAsset, audioAsset: AVURLAsset) async {
        do {
            // Load tracks
            async let vTracks = videoAsset.load(.tracks)
            async let aTracks = audioAsset.load(.tracks)
            
            let composition = AVMutableComposition()
            let compV = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
            let compA = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
            
            // Wait for tracks to be ready
            if let vTrack = try await vTracks.first, let aTrack = try await aTracks.first {
                // Load both time ranges to compare
                let vTrackTimeRange = try await vTrack.load(.timeRange)
                let aTrackTimeRange = try await aTrack.load(.timeRange)
                
                let vDuration = CMTimeGetSeconds(vTrackTimeRange.duration)
                let aDuration = CMTimeGetSeconds(aTrackTimeRange.duration)
                
                print("📊 [PLAYER] Video track: \(vDuration)s, Audio track: \(aDuration)s")
                
                // YouTube bug: Streams report double the actual duration
                let safeDuration = min(vDuration, aDuration) / 2.0
                
                print("✅ [PLAYER] Using half duration (\(safeDuration)s) to avoid YouTube duplicate bug")
                
                let timeRange = CMTimeRange(start: .zero, duration: CMTime(seconds: safeDuration, preferredTimescale: 600))
                
                try compV?.insertTimeRange(timeRange, of: vTrack, at: .zero)
                try compA?.insertTimeRange(timeRange, of: aTrack, at: .zero)
                
                print("✅ [PLAYER] Composition tracks inserted with duration: \(safeDuration)s")
                
                let playerItem = AVPlayerItem(asset: composition)
                playerItem.preferredForwardBufferDuration = 1.0
                
                await MainActor.run {
                    player.replaceCurrentItem(with: playerItem)
                    player.playImmediately(atRate: 1.0)
                }
            }
        } catch {
            print("⚠️ [PLAYER] Failed to create composition: \(error)")
            // Fall back to loading fresh
            await MainActor.run {
                loadVideo()
            }
        }
    }
    
    func loadVideo() {
        guard let url = URL(string: videoURL) else { dismiss(); return }
        
        Task {
            do {
                let youtube = YouTube(url: url, methods: [.remote, .local])
                let streams = try await youtube.streams
                
                // 1. FIXED CODEC FILTERING: Convert enum to string safely
                let bestVideo = streams.filter { stream in
                    let codecString = stream.videoCodec.map { "\($0)".lowercased() } ?? ""
                    return stream.audioCodec == nil && codecString.contains("avc1")
                }.highestResolutionStream()
                
                let bestAudio = streams.filter {
                    $0.videoCodec == nil && $0.audioCodec != nil
                }.highestResolutionStream()

                guard let vURL = bestVideo?.url, let aURL = bestAudio?.url else {
                    // Fallback to 720p progressive if 1080p muxed fails
                    if let fallback = streams.filter({ $0.isProgressive }).highestResolutionStream() {
                        setupPlayer(with: AVPlayerItem(url: fallback.url))
                    }
                    return
                }

                // 2. PARALLEL TRACK LOADING: Load tracks without blocking
                let videoAsset = AVURLAsset(url: vURL)
                let audioAsset = AVURLAsset(url: aURL)
                
                // Start loading tracks
                async let vTracks = videoAsset.load(.tracks)
                async let aTracks = audioAsset.load(.tracks)
                
                let composition = AVMutableComposition()
                let compV = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
                let compA = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
                
                // Wait for parallel loads to finish
                if let vTrack = try await vTracks.first, let aTrack = try await aTracks.first {
                    // Load both time ranges to compare
                    let vTrackTimeRange = try await vTrack.load(.timeRange)
                    let aTrackTimeRange = try await aTrack.load(.timeRange)
                    
                    let vDuration = CMTimeGetSeconds(vTrackTimeRange.duration)
                    let aDuration = CMTimeGetSeconds(aTrackTimeRange.duration)
                    
                    print("📊 [PLAYER] Fresh load - Video track: \(vDuration)s, Audio track: \(aDuration)s")
                    
                    // YouTube bug: Streams report double the actual duration
                    let safeDuration = min(vDuration, aDuration) / 2.0
                    
                    print("✅ [PLAYER] Using half duration (\(safeDuration)s) to avoid YouTube duplicate bug")
                    
                    let timeRange = CMTimeRange(start: .zero, duration: CMTime(seconds: safeDuration, preferredTimescale: 600))
                    
                    try compV?.insertTimeRange(timeRange, of: vTrack, at: .zero)
                    try compA?.insertTimeRange(timeRange, of: aTrack, at: .zero)
                    
                    print("✅ [PLAYER] Fresh composition created with duration: \(safeDuration)s")
                    
                    let playerItem = AVPlayerItem(asset: composition)
                    
                    // 3. SPEED TRICK: Don't wait for the whole file to buffer
                    playerItem.preferredForwardBufferDuration = 1.0
                    setupPlayer(with: playerItem)
                }
                
            } catch {
                print("Trailer Error: \(error)")
                await MainActor.run { dismiss() }
            }
        }
    }

    private func setupPlayer(with item: AVPlayerItem) {
        DispatchQueue.main.async {
            let newPlayer = AVPlayer(playerItem: item)
            
            // CRITICAL: Tell the player NOT to wait for a large buffer
            newPlayer.automaticallyWaitsToMinimizeStalling = false
            
            self.player = newPlayer
            
            // This command is more aggressive than .play()
            self.player.playImmediately(atRate: 1.0)
        }
    }
    
    private func setupEndDetection() {
        // Primary: Traditional notification (works reliably now that duration is correct)
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: nil,
            queue: .main
        ) { [self] _ in
            guard !hasReachedEnd else { return }
            hasReachedEnd = true
            print("🏁 [END] Video ended via notification")
            dismiss()
        }
        
        // Fallback: Polling to catch edge cases
        observerStoppedCheckTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [self] _ in
            guard !hasReachedEnd, let currentItem = player.currentItem else { return }
            
            let currentTime = currentItem.currentTime().seconds
            let duration = currentItem.duration.seconds
            
            guard duration.isFinite, duration > 0 else { return }
            
            // Simple end detection
            if currentTime >= duration - 0.5 {
                hasReachedEnd = true
                print("🏁 [END] Video ended via polling")
                dismiss()
            }
        }
    }
}
