//
//  TrailerPlayerView.swift
//  Reccs
//
//  Created by Evan Gedrich Pintado on 3/3/26.
//

import AVKit
import Combine
import os
import SwiftUI

/// Owns one movie's trailer playback. The detail page starts it so the trailer is resolved and
/// buffering before Play is pressed; the full-screen player only shows what it has.
@MainActor
@Observable
final class TrailerSession: Identifiable {
    enum Phase: Equatable {
        case idle
        case loading
        case ready
        case failed(String)
    }

    let link: String
    let title: String
    let player = AVPlayer()
    private(set) var phase: Phase = .idle
    /// Incremented when the trailer plays to the end, so the player view can close itself.
    private(set) var finishedCount = 0

    @ObservationIgnored private var media: TrailerMedia?
    @ObservationIgnored private var loadTask: Task<Void, Never>?
    @ObservationIgnored private var itemObservers: Set<AnyCancellable> = []
    @ObservationIgnored private var isPresented = false
    @ObservationIgnored private var hasRetriedFresh = false

    /// While the trailer sits paused behind the detail page, buffer only this much so it starts
    /// instantly without downloading the whole file. Lifted once playback starts.
    private let idleBufferDuration: TimeInterval = 10

    init(link: String, title: String) {
        self.link = link
        self.title = title
    }

    /// Resolves the trailer and attaches it to the (paused) player so AVFoundation starts buffering.
    /// Safe to call repeatedly; does nothing while loading or ready.
    func preload() {
        if let media, media.expiresAt <= .now {
            // YouTube's signed URLs have lapsed while the page sat open.
            reset()
        }
        guard phase == .idle || isFailed else { return }
        guard let reference = TrailerReference(link) else {
            phase = .failed(TrailerError.invalidLink.localizedDescription)
            return
        }

        phase = .loading
        loadTask = Task { [weak self] in
            do {
                let media = try await TrailerLoader.shared.media(for: reference)
                guard !Task.isCancelled else { return }
                self?.install(media)
            } catch {
                guard !Task.isCancelled else { return }
                self?.fail(with: error)
            }
        }
    }

    /// The full-screen player appeared.
    func startPlayback() {
        isPresented = true
        preload()
        guard phase == .ready, let item = player.currentItem else { return }
        let duration = item.duration
        if duration.isNumeric, item.currentTime().seconds >= duration.seconds - 1 {
            player.seek(to: .zero)
        }
        item.preferredForwardBufferDuration = 0 // let AVFoundation decide during playback
        player.play()
    }

    /// The full-screen player went away. Rewind so the next Play starts from the top, already buffered.
    func stopPlayback() {
        isPresented = false
        player.pause()
        if let item = player.currentItem {
            item.preferredForwardBufferDuration = idleBufferDuration
            player.seek(to: .zero)
        }
    }

    /// Leaving the movie page: release the stream and stop buffering.
    func tearDown() {
        isPresented = false
        reset()
    }

    /// Manual retry from the error screen: start over with freshly extracted URLs.
    func retry() {
        if let reference = TrailerReference(link) {
            TrailerLoader.shared.forget(reference)
        }
        hasRetriedFresh = false
        reset()
        preload()
    }

    // MARK: - Private

    private var isFailed: Bool {
        if case .failed = phase { return true }
        return false
    }

    private func reset() {
        loadTask?.cancel()
        loadTask = nil
        itemObservers.removeAll()
        player.pause()
        player.replaceCurrentItem(with: nil)
        media = nil
        phase = .idle
    }

    private func install(_ media: TrailerMedia, resumingAt time: CMTime? = nil) {
        self.media = media

        let item = AVPlayerItem(asset: media.asset)
        item.preferredForwardBufferDuration = isPresented ? 0 : idleBufferDuration
        let titleItem = AVMutableMetadataItem()
        titleItem.identifier = .commonIdentifierTitle
        titleItem.value = title as NSString
        titleItem.extendedLanguageTag = "und"
        item.externalMetadata = [titleItem]
        observe(item)

        player.replaceCurrentItem(with: item)
        if let time, time.isNumeric, time.seconds > 0 {
            player.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero)
        }
        phase = .ready
        if isPresented {
            player.play()
        }
    }

    private func observe(_ item: AVPlayerItem) {
        itemObservers.removeAll()
        item.publisher(for: \.status)
            .filter { $0 == .failed }
            .receive(on: RunLoop.main)
            .sink { [weak self, weak item] _ in
                self?.recover(from: item?.error)
            }
            .store(in: &itemObservers)
        NotificationCenter.default.publisher(for: AVPlayerItem.failedToPlayToEndTimeNotification, object: item)
            .receive(on: RunLoop.main)
            .sink { [weak self] note in
                self?.recover(from: note.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? Error)
            }
            .store(in: &itemObservers)
        NotificationCenter.default.publisher(for: AVPlayerItem.didPlayToEndTimeNotification, object: item)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.finishedCount += 1
            }
            .store(in: &itemObservers)
    }

    /// Playback broke (expired URL, network, decoder): step down to the next source, then try fresh
    /// URLs once, and only then show an error.
    private func recover(from error: Error?) {
        guard let media, phase == .ready else { return }
        trailerLog.error("Playback failed: \(error?.localizedDescription ?? "unknown", privacy: .public)")
        let position = player.currentTime()
        itemObservers.removeAll()
        phase = .loading

        loadTask = Task { [weak self] in
            do {
                var next: TrailerMedia?
                if !media.fallbacks.isEmpty {
                    next = try? await TrailerLoader.shared.fallback(after: media)
                }
                if next == nil, let self, !self.hasRetriedFresh {
                    // Every source from this extraction failed; the URLs themselves may be bad.
                    self.hasRetriedFresh = true
                    TrailerLoader.shared.forget(media.reference)
                    next = try await TrailerLoader.shared.media(for: media.reference)
                }
                guard let next else { throw error ?? TrailerError.noPlayableStreams }
                guard !Task.isCancelled else { return }
                self?.install(next, resumingAt: position)
            } catch {
                guard !Task.isCancelled else { return }
                self?.fail(with: error)
            }
        }
    }

    private func fail(with error: Error) {
        trailerLog.error("Trailer unavailable: \(error.localizedDescription, privacy: .public)")
        itemObservers.removeAll()
        player.replaceCurrentItem(with: nil)
        media = nil
        phase = .failed((error as? TrailerError)?.localizedDescription
            ?? "The trailer couldn't be loaded from YouTube right now.")
    }
}

struct TrailerPlayerView: View {
    let session: TrailerSession
    @Environment(\.dismiss) private var dismiss
    @State private var isBuffering = true
    @State private var showSlowLoadingHint = false
    @State private var appearedAt = Date()
    @State private var hasStarted = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            switch session.phase {
            case .failed(let message):
                failureView(message)
            default:
                VideoPlayer(player: session.player)
                    .ignoresSafeArea()

                if session.phase != .ready || isBuffering {
                    VStack(spacing: 24) {
                        ProgressView()
                        if showSlowLoadingHint {
                            Text("Loading trailer…")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white.opacity(0.8))
                                .transition(.opacity)
                        }
                    }
                    .allowsHitTesting(false)
                }
            }
        }
        .onAppear {
            appearedAt = Date()
            session.startPlayback()
        }
        .onDisappear {
            session.stopPlayback()
        }
        .task {
            try? await Task.sleep(for: .seconds(3))
            withAnimation { showSlowLoadingHint = true }
        }
        .onReceive(session.player.publisher(for: \.timeControlStatus)) { status in
            withAnimation(.easeInOut(duration: 0.3)) {
                isBuffering = status != .playing
            }
            if status == .playing, !hasStarted {
                hasStarted = true
                trailerLog.info("Playback started \(Date().timeIntervalSince(appearedAt), format: .fixed(precision: 2))s after Play")
            }
        }
        .onChange(of: session.finishedCount) {
            dismiss()
        }
    }

    private func failureView(_ message: String) -> some View {
        VStack(spacing: 40) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.yellow)
            VStack(spacing: 12) {
                Text("Trailer Unavailable")
                    .font(.title2)
                    .fontWeight(.bold)
                Text(message)
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 900)
            }
            HStack(spacing: 30) {
                Button("Try Again") {
                    session.retry()
                    session.startPlayback()
                }
                if let url = URL(string: session.link) {
                    Button("Open in YouTube") {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Close") {
                    dismiss()
                }
            }
        }
    }
}
