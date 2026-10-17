//
//  TrailerLoader.swift
//  Reccs
//
//  Turns a YouTube trailer link into a ready-to-play AVAsset at the best quality
//  this device can decode. YouTubeKit is an unofficial client and YouTube changes
//  often, so every step here is allowed to fail and has a fallback.
//

import AVFoundation
import Foundation
import os
import YouTubeKit

nonisolated let trailerLog = Logger(subsystem: "com.evangedrich.Reccs", category: "Trailer")

enum TrailerError: LocalizedError {
    case invalidLink
    case noPlayableStreams
    case timedOut

    var errorDescription: String? {
        switch self {
        case .invalidLink: "This trailer link isn't a YouTube video."
        case .noPlayableStreams: "YouTube didn't return a version of this trailer that can play here."
        case .timedOut: "YouTube took too long to respond."
        }
    }
}

/// A YouTube link reduced to what playback needs: the video ID and an optional start offset (`?t=`).
struct TrailerReference: Hashable {
    let videoID: String
    let startTime: Double

    init?(_ link: String) {
        guard let components = URLComponents(string: link.trimmingCharacters(in: .whitespacesAndNewlines)),
              let host = components.host?.lowercased() else { return nil }
        let path = components.path.split(separator: "/").map(String.init)
        let query = components.queryItems ?? []

        var id: String?
        if host.hasSuffix("youtu.be") {
            id = path.first
        } else if host.contains("youtube") {
            if let v = query.first(where: { $0.name == "v" })?.value {
                id = v
            } else if path.count >= 2, ["embed", "shorts", "live", "v"].contains(path[0]) {
                id = path[1]
            }
        }
        guard let id, id.count == 11, id.allSatisfy({ $0.isLetter || $0.isNumber || $0 == "-" || $0 == "_" }) else {
            return nil
        }
        videoID = id
        let offset = query.first(where: { $0.name == "t" || $0.name == "start" })?.value
        startTime = offset.flatMap(Self.seconds(from:)) ?? 0
    }

    /// Parses YouTube offsets like "4", "4s", "1m30s" or "1h2m3s".
    private static func seconds(from value: String) -> Double? {
        if let plain = Double(value) { return max(0, plain) }
        var total = 0.0
        var number = ""
        for character in value.lowercased() {
            if character.isNumber {
                number.append(character)
            } else {
                guard let amount = Double(number) else { return nil }
                switch character {
                case "h": total += amount * 3600
                case "m": total += amount * 60
                case "s": total += amount
                default: return nil
                }
                number = ""
            }
        }
        return number.isEmpty ? total : nil
    }
}

/// One way to play a trailer: separate video + audio streams (how YouTube serves anything above 360p),
/// or a single stream carrying both.
enum TrailerSource {
    case split(video: YouTubeKit.Stream, audio: YouTubeKit.Stream)
    case muxed(YouTubeKit.Stream)

    var streams: [YouTubeKit.Stream] {
        switch self {
        case .split(let video, let audio): [video, audio]
        case .muxed(let stream): [stream]
        }
    }

    var resolution: Int {
        switch self {
        case .split(let video, _): video.videoResolution ?? 0
        case .muxed(let stream): stream.videoResolution ?? 0
        }
    }

    /// Real length in seconds, from the `dur` parameter YouTube signs into every stream URL.
    /// AVFoundation's own estimate for these fragmented MP4s is unreliable (often ~2x too long).
    var duration: Double? {
        streams.compactMap { $0.url.queryValue("dur").flatMap(Double.init) }.min()
    }

    /// When YouTube stops honouring these URLs (the signed `expire` parameter), with a safety margin.
    var expiresAt: Date {
        let expiries = streams.compactMap { $0.url.queryValue("expire").flatMap(TimeInterval.init) }
        guard let earliest = expiries.min() else { return .now.addingTimeInterval(30 * 60) }
        return Date(timeIntervalSince1970: earliest).addingTimeInterval(-10 * 60)
    }

    /// The best audio-only stream: AAC first (universally supported), then highest bitrate.
    nonisolated static func bestAudio(in streams: [YouTubeKit.Stream]) -> YouTubeKit.Stream? {
        streams
            .filter { $0.includesAudioTrack && !$0.includesVideoTrack }
            .max { ($0.audioCodec == .mp4a ? 1 : 0, $0.bitrate ?? 0) < ($1.audioCodec == .mp4a ? 1 : 0, $1.bitrate ?? 0) }
    }

    /// Every combination this device can decode, best first: highest resolution, then the
    /// more efficient codec (AV1 is only offered where it is hardware-decoded), then split over muxed.
    static func ranked(from streams: [YouTubeKit.Stream]) -> [TrailerSource] {
        // AVFoundation can only open MP4-family containers; WebM (VP9/Opus) never plays.
        let playable = streams.filter { $0.isNativelyPlayable && [.mp4, .m4a].contains($0.fileExtension) }

        let audio = bestAudio(in: playable)

        var sources: [TrailerSource] = []
        if let audio {
            let videos = playable
                .filter { $0.includesVideoTrack && !$0.includesAudioTrack }
                .sorted { a, b in
                    let ra = a.videoResolution ?? 0, rb = b.videoResolution ?? 0
                    if ra != rb { return ra > rb }
                    let av1a = a.videoCodec == .av1, av1b = b.videoCodec == .av1
                    if av1a != av1b { return av1a }
                    return (a.bitrate ?? 0) < (b.bitrate ?? 0)
                }
            sources += videos.map { .split(video: $0, audio: audio) }
        }
        sources += playable
            .filter { $0.isProgressive }
            .sorted { ($0.videoResolution ?? 0) > ($1.videoResolution ?? 0) }
            .map { .muxed($0) }

        return sources.enumerated()
            .sorted { lhs, rhs in
                lhs.element.resolution != rhs.element.resolution
                    ? lhs.element.resolution > rhs.element.resolution
                    : lhs.offset < rhs.offset
            }
            .map(\.element)
    }
}

/// A trailer ready for an AVPlayerItem, plus what's needed to step down if it fails mid-play.
struct TrailerMedia {
    let reference: TrailerReference
    let asset: AVAsset
    /// Fixed-quality versions to fall back on if the adaptive stream fails.
    let fallbacks: [TrailerSource]
    let expiresAt: Date
    /// Serves the generated HLS playlists; the asset only holds it weakly, so the media keeps it alive.
    let playlistLoader: HLSPlaylistLoader?
}

/// Resolves trailers once and shares the result: the detail page preloads, the player reuses it,
/// and revisiting a movie within the URL lifetime is instant.
@MainActor
final class TrailerLoader {
    static let shared = TrailerLoader()

    /// How long one extraction method may take before we stop waiting on it.
    private let extractionTimeout: Double = 20
    /// How long building a playable asset from one source may take (it's the first network touch of the media).
    private let assetTimeout: Double = 15
    /// How long fetching every stream header and validating the HLS playlists may take.
    private let hlsTimeout: Double = 10
    /// Sources to try before giving up; each failure is usually systemic (e.g. every URL 403s).
    private let maxSourceAttempts = 3

    private var cache: [TrailerReference: TrailerMedia] = [:]
    private var inFlight: [TrailerReference: Task<TrailerMedia, Error>] = [:]

    func media(for reference: TrailerReference) async throws -> TrailerMedia {
        if let cached = cache[reference], cached.expiresAt > .now {
            return cached
        }
        if let running = inFlight[reference] {
            return try await running.value
        }
        let task = Task { try await resolve(reference) }
        inFlight[reference] = task
        defer { inFlight[reference] = nil }
        let media = try await task.value
        cache[reference] = media
        return media
    }

    /// Builds an asset from a lower-quality source after the current one failed during playback.
    func fallback(after media: TrailerMedia) async throws -> TrailerMedia {
        cache[media.reference] = nil
        for (index, source) in media.fallbacks.prefix(maxSourceAttempts).enumerated() {
            do {
                let asset = try await withTimeout(assetTimeout) {
                    try await Self.makeAsset(for: source, startingAt: media.reference.startTime)
                }.asset
                let next = TrailerMedia(
                    reference: media.reference,
                    asset: asset,
                    fallbacks: Array(media.fallbacks.dropFirst(index + 1)),
                    expiresAt: source.expiresAt,
                    playlistLoader: nil
                )
                cache[media.reference] = next
                return next
            } catch {
                trailerLog.error("Fallback \(source.resolution)p failed: \(error.localizedDescription, privacy: .public)")
            }
        }
        throw TrailerError.noPlayableStreams
    }

    func forget(_ reference: TrailerReference) {
        cache[reference] = nil
    }

    // MARK: - Resolution

    /// Extracts with YouTubeKit's remote service, falling back to on-device extraction, and prefers an
    /// adaptive HLS stream built from the result, then fixed-quality compositions.
    private func resolve(_ reference: TrailerReference) async throws -> TrailerMedia {
        let started = Date()
        var lastError: Error = TrailerError.noPlayableStreams

        for (name, method) in [("remote", YouTube.ExtractionMethod.remote), ("local", .local)] {
            let streams: [YouTubeKit.Stream]
            do {
                streams = try await withTimeout(extractionTimeout) {
                    try await YouTube(videoID: reference.videoID, methods: [method]).streams
                }
            } catch {
                trailerLog.error("\(name, privacy: .public) extraction failed for \(reference.videoID, privacy: .public): \(error.localizedDescription, privacy: .public)")
                lastError = error
                continue
            }

            let sources = TrailerSource.ranked(from: streams)
            trailerLog.info("\(name, privacy: .public) extraction: \(streams.count) streams, best \(sources.first?.resolution ?? 0)p, \(Date().timeIntervalSince(started), format: .fixed(precision: 1))s")
            guard !sources.isEmpty else { continue }

            do {
                let adaptive = try await withTimeout(hlsTimeout) {
                    try await Self.makeAdaptiveAsset(from: streams, reference: reference)
                }
                trailerLog.info("Ready: \(reference.videoID, privacy: .public) adaptive up to \(adaptive.maxResolution)p via \(name, privacy: .public) in \(Date().timeIntervalSince(started), format: .fixed(precision: 1))s")
                return TrailerMedia(
                    reference: reference,
                    asset: adaptive.asset,
                    fallbacks: sources,
                    expiresAt: adaptive.expiresAt,
                    playlistLoader: adaptive.loader
                )
            } catch {
                trailerLog.error("\(name, privacy: .public) adaptive stream unusable: \(error.localizedDescription, privacy: .public)")
                lastError = error
            }

            for (index, source) in sources.prefix(maxSourceAttempts).enumerated() {
                do {
                    let asset = try await withTimeout(assetTimeout) {
                        try await Self.makeAsset(for: source, startingAt: reference.startTime)
                    }.asset
                    trailerLog.info("Ready: \(reference.videoID, privacy: .public) at \(source.resolution)p via \(name, privacy: .public) in \(Date().timeIntervalSince(started), format: .fixed(precision: 1))s")
                    return TrailerMedia(
                        reference: reference,
                        asset: asset,
                        fallbacks: Array(sources.dropFirst(index + 1)),
                        expiresAt: source.expiresAt,
                        playlistLoader: nil
                    )
                } catch {
                    trailerLog.error("\(name, privacy: .public) \(source.resolution)p unusable: \(error.localizedDescription, privacy: .public)")
                    lastError = error
                }
            }
        }
        throw lastError
    }

    /// Describes every playable resolution as one HLS stream so AVPlayer can start fast and adapt to the
    /// network. Fetching each stream's header (~1 KB) also proves the URLs work before Play is pressed.
    private nonisolated static func makeAdaptiveAsset(
        from streams: [YouTubeKit.Stream],
        reference: TrailerReference
    ) async throws -> AdaptiveAsset {
        let playable = streams.filter { $0.isNativelyPlayable && [.mp4, .m4a].contains($0.fileExtension) }
        // One video stream per resolution, preferring AV1 (only "natively playable" where hardware-decoded).
        let videoByResolution = Dictionary(grouping: playable.filter { $0.includesVideoTrack && !$0.includesAudioTrack }) {
            $0.videoResolution ?? 0
        }
        let videos = videoByResolution.values.compactMap { candidates in
            candidates.first { $0.videoCodec == .av1 } ?? candidates.first { $0.videoCodec == .avc1 }
        }
        guard let audio = TrailerSource.bestAudio(in: playable), !videos.isEmpty else {
            throw TrailerError.noPlayableStreams
        }

        let renditions = await withTaskGroup(of: HLSRendition?.self) { group in
            for stream in videos + [audio] {
                group.addTask { try? await TrailerHLS.rendition(for: stream) }
            }
            var results: [HLSRendition] = []
            for await rendition in group {
                if let rendition { results.append(rendition) }
            }
            return results
        }
        guard let audioRendition = renditions.first(where: { !$0.stream.includesVideoTrack }) else {
            throw TrailerError.noPlayableStreams
        }
        // Highest first: AVPlayer starts on the first variant, and the detail page has already buffered it.
        let videoRenditions = renditions
            .filter { $0.stream.includesVideoTrack }
            .sorted { $0.bandwidth > $1.bandwidth }
        guard !videoRenditions.isEmpty else { throw TrailerError.noPlayableStreams }

        let duration = videoRenditions[0].duration
        let startTime = reference.startTime < duration - 5 ? reference.startTime : 0
        let id = "\(reference.videoID)-\(UUID().uuidString.prefix(8))"
        var playlists = ["audio.m3u8": audioRendition.playlist]
        for (index, video) in videoRenditions.enumerated() {
            playlists["video\(index).m3u8"] = video.playlist
        }
        playlists["master.m3u8"] = TrailerHLS.masterPlaylist(
            videos: videoRenditions,
            audio: audioRendition,
            videoURL: { video in
                HLSPlaylistLoader.url(id: id, name: "video\(videoRenditions.firstIndex { $0.stream.url == video.stream.url } ?? 0).m3u8")
            },
            audioURL: HLSPlaylistLoader.url(id: id, name: "audio.m3u8"),
            startTime: startTime
        )

        let loader = HLSPlaylistLoader(id: id, playlists: playlists)
        let asset = AVURLAsset(url: loader.masterURL)
        asset.resourceLoader.setDelegate(loader, queue: HLSPlaylistLoader.queue)
        guard try await asset.load(.isPlayable) else { throw TrailerError.noPlayableStreams }

        let sources = videoRenditions.map(\.stream) + [audioRendition.stream]
        let expiries = sources.compactMap { $0.url.queryValue("expire").flatMap(TimeInterval.init) }
        return AdaptiveAsset(
            asset: asset,
            loader: loader,
            maxResolution: videoRenditions.compactMap { $0.stream.videoResolution }.max() ?? 0,
            expiresAt: expiries.min().map { Date(timeIntervalSince1970: $0).addingTimeInterval(-10 * 60) }
                ?? .now.addingTimeInterval(30 * 60)
        )
    }

    /// Stitches the source's tracks into one composition trimmed to the real duration and start offset.
    /// Loading the tracks also proves the URLs are reachable before anyone presses play.
    private static func makeAsset(for source: TrailerSource, startingAt start: Double) async throws -> FinishedAsset {
        let assets = source.streams.map {
            AVURLAsset(url: $0.url, options: [AVURLAssetPreferPreciseDurationAndTimingKey: false])
        }
        let trackLists = try await withThrowingTaskGroup(of: (Int, [AVAssetTrack]).self) { group in
            for (index, asset) in assets.enumerated() {
                group.addTask { (index, try await asset.load(.tracks)) }
            }
            var lists = Array(repeating: [AVAssetTrack](), count: assets.count)
            for try await (index, tracks) in group { lists[index] = tracks }
            return lists
        }

        let video = trackLists.lazy.flatMap { $0 }.first { $0.mediaType == .video }
        let audio = trackLists.lazy.flatMap { $0 }.first { $0.mediaType == .audio }
        guard let video else { throw TrailerError.noPlayableStreams }

        let videoRange = try await video.load(.timeRange)
        let audioRange = try await audio?.load(.timeRange)
        var end = videoRange.end
        if let audioRange { end = min(end, audioRange.end) }
        if let duration = source.duration { end = min(end, CMTime(seconds: duration, preferredTimescale: 600)) }

        // Ignore offsets that would leave less than a few seconds of trailer.
        var rangeStart = max(videoRange.start, audioRange?.start ?? .zero)
        if start > 0, start < end.seconds - 5 {
            rangeStart = max(rangeStart, CMTime(seconds: start, preferredTimescale: 600))
        }
        let range = CMTimeRange(start: rangeStart, end: end)
        guard range.duration.seconds > 1 else { throw TrailerError.noPlayableStreams }

        let composition = AVMutableComposition()
        for track in [video, audio].compactMap({ $0 }) {
            guard let compositionTrack = composition.addMutableTrack(
                withMediaType: track.mediaType,
                preferredTrackID: kCMPersistentTrackID_Invalid
            ) else { throw TrailerError.noPlayableStreams }
            try compositionTrack.insertTimeRange(range, of: track, at: .zero)
            if track.mediaType == .video {
                compositionTrack.preferredTransform = try await track.load(.preferredTransform)
            }
        }
        return FinishedAsset(asset: composition)
    }
}

/// The HLS asset and the loader serving its playlists, handed back from a background task.
struct AdaptiveAsset: @unchecked Sendable {
    let asset: AVAsset
    let loader: HLSPlaylistLoader
    let maxResolution: Int
    let expiresAt: Date
}

/// A composition that is no longer mutated once built, so it can be handed across tasks.
struct FinishedAsset: @unchecked Sendable {
    let asset: AVAsset
}

/// Runs `operation`, throwing `TrailerError.timedOut` if it hasn't finished after `seconds`.
nonisolated func withTimeout<T: Sendable>(
    _ seconds: Double,
    _ operation: @escaping @Sendable () async throws -> T
) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
        group.addTask { try await operation() }
        group.addTask {
            try await Task.sleep(for: .seconds(seconds))
            throw TrailerError.timedOut
        }
        defer { group.cancelAll() }
        guard let result = try await group.next() else { throw TrailerError.timedOut }
        return result
    }
}

extension URL {
    func queryValue(_ name: String) -> String? {
        URLComponents(url: self, resolvingAgainstBaseURL: false)?
            .queryItems?.first { $0.name == name }?.value
    }
}
