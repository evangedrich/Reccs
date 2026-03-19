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
    let preloadState: TrailerPreloadState // Receive the shared observable state
    @Environment(\.dismiss) var dismiss
    @State private var player = AVPlayer()
    
    @State private var isBuffering = true
    @State private var showLongLoadingMessage = false
    @State private var hasReachedEnd = false // Prevent multiple dismiss calls
    @State private var observerStoppedCheckTimer: Timer?
    @State private var lastKnownTime: Double = 0
    @State private var timeStuckCount: Int = 0
    @State private var videoStartedPlaying = false // Track if video has started
    @State private var stallCount: Int = 0 // Track how many times we've stalled

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
            // Clean up: stop the player and remove observers
            player.pause()
            observerStoppedCheckTimer?.invalidate()
            NotificationCenter.default.removeObserver(self)
        }
        // Detect when video starts to hide the message
        .onReceive(player.publisher(for: \.timeControlStatus)) { status in
            if status == .playing {
                withAnimation(.easeInOut(duration: 0.5)) {
                    isBuffering = false
                }
                videoStartedPlaying = true
            }
        }
        // Additional monitoring: detect when playback pauses after it started
        .onReceive(player.publisher(for: \.rate)) { rate in
            // If video was playing and now stopped (rate = 0), check if it's the end
            if videoStartedPlaying && rate == 0 && !hasReachedEnd {
                print("🛑 [RATE] Player stopped (rate=0) after playing")
                
                // Give it a moment - could be buffering
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    guard !hasReachedEnd, 
                          player.rate == 0, // Still stopped
                          player.timeControlStatus == .paused, // Actually paused, not buffering
                          let currentItem = player.currentItem else { return }
                    
                    let currentTime = currentItem.currentTime().seconds
                    let duration = currentItem.duration.seconds
                    
                    print("🛑 [RATE CHECK] Still stopped - Time: \(currentTime)s/\(duration)s, Status: \(player.timeControlStatus.rawValue)")
                    
                    // If we're anywhere past the halfway point and player genuinely stopped, assume it's done
                    // (The composition bug means currentTime is unreliable, but the rate stopping IS reliable)
                    if currentTime > duration * 0.5 && duration.isFinite && duration > 10 {
                        hasReachedEnd = true
                        print("🏁 [END] Video ended via rate=0 detection (stopped after playing)")
                        dismiss()
                    }
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
                // Use half the duration for compositions to avoid playing duplicated content
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
                    // Use half the duration for compositions to avoid playing duplicated content
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
        // METHOD 1: Traditional notification (most reliable for normal playback)
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
        
        // METHOD 2: Aggressive polling with stall detection
        observerStoppedCheckTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { [self] _ in
            guard !hasReachedEnd, let currentItem = player.currentItem else { return }
            
            let currentTime = currentItem.currentTime().seconds
            let duration = currentItem.duration.seconds
            let rate = player.rate
            let status = player.timeControlStatus
            
            // Only check if we have valid duration
            guard duration.isFinite, duration > 0 else { return }
            
            // Log periodically to see what's happening
            if Int(currentTime) % 10 == 0 && currentTime > 0 {
                print("⏱️ [POLL] Time: \(currentTime)s/\(duration)s, Rate: \(rate), Status: \(status.rawValue)")
            }
            
            // DETECTION 1: Near the end based on reported time
            if currentTime >= duration - 0.5 {
                hasReachedEnd = true
                print("🏁 [END] Video ended via polling - current: \(currentTime)s, duration: \(duration)s")
                dismiss()
                return
            }
            
            // DETECTION 2: Stalling detection (network stream exhausted)
            // When the stream runs out of data (actual video ended), player stalls
            if status == .waitingToPlayAtSpecifiedRate && videoStartedPlaying && rate > 0 {
                stallCount += 1
                print("⚠️ [STALL] Player stalled (\(stallCount) x 0.3s) at \(currentTime)s - waiting for data that may not exist")
                
                // If stalled for 3+ seconds (10 checks) while supposedly "playing"
                // This indicates the stream has no more data (it ended)
                if stallCount >= 10 {
                    hasReachedEnd = true
                    print("🏁 [END] Video ended via stall detection (stream exhausted at \(currentTime)s of claimed \(duration)s)")
                    dismiss()
                    return
                }
            } else if status == .playing {
                // Reset stall counter when playing resumes
                stallCount = 0
            }
            
            // DETECTION 3: YouTube duplicate bug - Time frozen at exactly half duration
            // This happens when YouTube serves the video twice but playback stops after the first copy
            let halfDuration = duration / 2.0
            if abs(currentTime - halfDuration) < 2.0 {  // Within 2 seconds of halfway point
                // Check if time is frozen
                if abs(currentTime - lastKnownTime) < 0.05 {
                    timeStuckCount += 1
                    
                    // If stuck at the halfway mark for 2 seconds while "playing"
                    if timeStuckCount >= 6 && rate > 0 {
                        hasReachedEnd = true
                        print("🏁 [END] Video ended via YouTube duplicate detection (frozen at \(currentTime)s = half of \(duration)s)")
                        dismiss()
                        return
                    }
                }
            } else {
                // Not at halfway point, check for general freezing
                if abs(currentTime - lastKnownTime) < 0.05 {
                    if rate > 0 && status == .playing {
                        timeStuckCount += 1
                        
                        // If stuck for 3+ seconds anywhere while "playing" and past 10s mark
                        if timeStuckCount >= 10 && currentTime > 10 {
                            print("⚠️ [FROZEN] Time frozen at \(currentTime)s for \(Double(timeStuckCount * 3) / 10.0)s while rate=\(rate)")
                            hasReachedEnd = true
                            print("🏁 [END] Video ended via frozen time detection")
                            dismiss()
                            return
                        }
                    }
                } else {
                    // Time is moving, reset counter
                    timeStuckCount = 0
                }
            }
            
            lastKnownTime = currentTime
            
            // DETECTION 4: Player stopped near the end
            if rate == 0 && currentTime >= duration - 2.0 && status != .waitingToPlayAtSpecifiedRate {
                hasReachedEnd = true
                print("🏁 [END] Video ended via polling (stopped near end) - current: \(currentTime)s, duration: \(duration)s")
                dismiss()
            }
        }
    }
}
