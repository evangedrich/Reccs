//
//  TrailerHLS.swift
//  Reccs
//
//  YouTube serves trailers as separate fragmented-MP4 video and audio files ("DASH"). Each file
//  begins with an init segment and a segment index (sidx), so from ~1 KB per file we can describe
//  it as an HLS media playlist of byte ranges into YouTube's own URLs. AVPlayer then streams it
//  natively: fast start, adaptive quality across every resolution, exact duration, A/V in sync.
//

import AVFoundation
import Foundation
import YouTubeKit

/// One YouTube stream described as an HLS media playlist.
nonisolated struct HLSRendition: Sendable {
    let stream: YouTubeKit.Stream
    let codecs: String
    let bandwidth: Int
    let averageBandwidth: Int?
    let width: Int?
    let height: Int?
    let playlist: String
    let duration: Double
}

nonisolated enum TrailerHLS {
    /// Bytes fetched from the start of each stream; YouTube's init segment + sidx fit in ~1 KB.
    static let headerBytes = 16 * 1024

    enum ParseError: Error {
        case missingBox(String)
        case unsupportedIndex
        case badResponse(Int)
    }

    /// Reads the head of `stream` and turns its segment index into an HLS media playlist.
    static func rendition(for stream: YouTubeKit.Stream, session: URLSession = .shared) async throws -> HLSRendition {
        var request = URLRequest(url: stream.url)
        request.setValue("bytes=0-\(headerBytes - 1)", forHTTPHeaderField: "Range")
        request.timeoutInterval = 10
        let (data, response) = try await session.data(for: request)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw ParseError.badResponse(http.statusCode)
        }

        let boxes = MP4Box.topLevel(in: data)
        guard let moov = boxes.first(where: { $0.type == "moov" }) else { throw ParseError.missingBox("moov") }
        guard let sidxBox = boxes.first(where: { $0.type == "sidx" }), sidxBox.end <= data.count else {
            throw ParseError.missingBox("sidx")
        }
        let index = try SegmentIndex(data: data, box: sidxBox)
        let size = MP4Box.trackDimensions(in: data, moov: moov)

        var lines = [
            "#EXTM3U",
            "#EXT-X-VERSION:7",
            "#EXT-X-TARGETDURATION:\(Int(index.segments.map(\.duration).max()?.rounded(.up) ?? 10))",
            "#EXT-X-PLAYLIST-TYPE:VOD",
            "#EXT-X-INDEPENDENT-SEGMENTS",
            "#EXT-X-MAP:URI=\"\(stream.url.absoluteString)\",BYTERANGE=\"\(moov.end)@0\"",
        ]
        for segment in index.segments {
            lines.append("#EXTINF:\(String(format: "%.6f", segment.duration)),")
            lines.append("#EXT-X-BYTERANGE:\(segment.length)@\(segment.offset)")
            lines.append(stream.url.absoluteString)
        }
        lines.append("#EXT-X-ENDLIST")

        let duration = index.segments.reduce(0) { $0 + $1.duration }
        let measured = duration > 0 ? Int(Double(index.segments.reduce(0) { $0 + $1.length }) * 8 / duration) : 0
        return HLSRendition(
            stream: stream,
            codecs: try codecString(for: stream),
            bandwidth: max(stream.bitrate ?? 0, measured),
            averageBandwidth: stream.averageBitrate,
            width: size?.width,
            height: size?.height,
            playlist: lines.joined(separator: "\n") + "\n",
            duration: duration
        )
    }

    /// The master playlist: every video rendition as a variant sharing one audio rendition.
    static func masterPlaylist(
        videos: [HLSRendition],
        audio: HLSRendition,
        videoURL: (HLSRendition) -> String,
        audioURL: String,
        startTime: Double
    ) -> String {
        var lines = ["#EXTM3U", "#EXT-X-VERSION:7", "#EXT-X-INDEPENDENT-SEGMENTS"]
        if startTime > 0 {
            lines.append("#EXT-X-START:TIME-OFFSET=\(String(format: "%.3f", startTime)),PRECISE=YES")
        }
        lines.append("#EXT-X-MEDIA:TYPE=AUDIO,GROUP-ID=\"audio\",NAME=\"Original\",DEFAULT=YES,AUTOSELECT=YES,URI=\"\(audioURL)\"")
        for video in videos {
            var attributes = [
                "BANDWIDTH=\(video.bandwidth + audio.bandwidth)",
                "CODECS=\"\(video.codecs),\(audio.codecs)\"",
                "AUDIO=\"audio\"",
            ]
            if let average = video.averageBandwidth {
                attributes.append("AVERAGE-BANDWIDTH=\(average + (audio.averageBandwidth ?? audio.bandwidth))")
            }
            if let width = video.width, let height = video.height {
                attributes.append("RESOLUTION=\(width)x\(height)")
            }
            lines.append("#EXT-X-STREAM-INF:" + attributes.joined(separator: ","))
            lines.append(videoURL(video))
        }
        return lines.joined(separator: "\n") + "\n"
    }

    /// RFC 6381 codec strings, rebuilt from what YouTubeKit parsed out of the MIME type.
    static func codecString(for stream: YouTubeKit.Stream) throws -> String {
        if let video = stream.videoCodec {
            switch video {
            case .avc1(let version): return "avc1.\(version)"
            case .av1(let version): return "av01.\(version)"
            case .mp4v(let version): return "mp4v.\(version)"
            default: throw ParseError.unsupportedIndex
            }
        }
        switch stream.audioCodec {
        case .mp4a(let version): return "mp4a.\(version)"
        case .ec3: return "ec-3"
        case .ac3: return "ac-3"
        default: throw ParseError.unsupportedIndex
        }
    }
}

// MARK: - MP4 parsing

nonisolated struct MP4Box {
    let type: String
    let start: Int
    let headerSize: Int
    let size: Int
    var end: Int { start + size }
    var payloadStart: Int { start + headerSize }

    /// Walks consecutive boxes in `data[range]`, stopping at the first truncated or malformed header.
    static func children(in data: Data, range: Range<Int>) -> [MP4Box] {
        var boxes: [MP4Box] = []
        var offset = range.lowerBound
        while offset + 8 <= range.upperBound {
            var size = Int(data.uint32(at: offset))
            let type = String(decoding: data.subdata(in: data.startIndex + offset + 4 ..< data.startIndex + offset + 8), as: UTF8.self)
            var header = 8
            if size == 1 {
                guard offset + 16 <= range.upperBound else { break }
                size = Int(data.uint64(at: offset + 8))
                header = 16
            } else if size == 0 {
                size = range.upperBound - offset
            }
            guard size >= header else { break }
            boxes.append(MP4Box(type: type, start: offset, headerSize: header, size: size))
            offset += size
        }
        return boxes
    }

    static func topLevel(in data: Data) -> [MP4Box] {
        children(in: data, range: 0..<data.count)
    }

    /// Display size from the first video track header (moov/trak/tkhd), if present.
    static func trackDimensions(in data: Data, moov: MP4Box) -> (width: Int, height: Int)? {
        guard moov.end <= data.count else { return nil }
        for trak in children(in: data, range: moov.payloadStart..<moov.end) where trak.type == "trak" {
            guard let tkhd = children(in: data, range: trak.payloadStart..<trak.end).first(where: { $0.type == "tkhd" }),
                  tkhd.end <= data.count, tkhd.size >= 84 else { continue }
            // Width and height are the last two 16.16 fixed-point fields of tkhd.
            let width = Int(data.uint32(at: tkhd.end - 8) >> 16)
            let height = Int(data.uint32(at: tkhd.end - 4) >> 16)
            if width > 0, height > 0 { return (width, height) }
        }
        return nil
    }
}

/// The `sidx` box: byte ranges and durations of every fragment that follows it.
nonisolated struct SegmentIndex {
    struct Segment {
        let offset: Int
        let length: Int
        let duration: Double
    }

    let segments: [Segment]

    init(data: Data, box: MP4Box) throws {
        var cursor = box.payloadStart
        let version = data.uint8(at: cursor)
        cursor += 4 // version + flags
        cursor += 4 // reference_ID
        let timescale = Double(data.uint32(at: cursor))
        cursor += 4
        let firstOffset: Int
        if version == 0 {
            cursor += 4 // earliest_presentation_time
            firstOffset = Int(data.uint32(at: cursor))
            cursor += 4
        } else {
            cursor += 8
            firstOffset = Int(data.uint64(at: cursor))
            cursor += 8
        }
        cursor += 2 // reserved
        let count = Int(data.uint16(at: cursor))
        cursor += 2
        guard timescale > 0, count > 0, cursor + count * 12 <= box.end else { throw TrailerHLS.ParseError.unsupportedIndex }

        var offset = box.end + firstOffset
        var segments: [Segment] = []
        for _ in 0..<count {
            let reference = data.uint32(at: cursor)
            // A set top bit points at another sidx (hierarchical index); YouTube doesn't use those.
            guard reference & 0x8000_0000 == 0 else { throw TrailerHLS.ParseError.unsupportedIndex }
            let length = Int(reference & 0x7FFF_FFFF)
            let duration = Double(data.uint32(at: cursor + 4)) / timescale
            segments.append(Segment(offset: offset, length: length, duration: duration))
            offset += length
            cursor += 12
        }
        self.segments = segments
    }
}

private extension Data {
    nonisolated func uint8(at offset: Int) -> UInt8 { self[startIndex + offset] }
    nonisolated func uint16(at offset: Int) -> UInt16 { UInt16(uint8(at: offset)) << 8 | UInt16(uint8(at: offset + 1)) }
    nonisolated func uint32(at offset: Int) -> UInt32 { (0..<4).reduce(0) { $0 << 8 | UInt32(uint8(at: offset + $1)) } }
    nonisolated func uint64(at offset: Int) -> UInt64 { (0..<8).reduce(0) { $0 << 8 | UInt64(uint8(at: offset + $1)) } }
}

// MARK: - Serving the playlists

/// Hands the generated playlists to AVFoundation through a private URL scheme. Media segments
/// keep their https URLs, so AVFoundation fetches those from YouTube directly.
final class HLSPlaylistLoader: NSObject, AVAssetResourceLoaderDelegate {
    nonisolated static let scheme = "reccs-hls"
    nonisolated static let queue = DispatchQueue(label: "com.evangedrich.Reccs.hls-playlists")
    nonisolated private let playlists: [String: Data]
    nonisolated let masterURL: URL

    /// The URL a playlist named `name` is served at for the trailer `id`.
    nonisolated static func url(id: String, name: String) -> String {
        "\(scheme)://\(id)/\(name)"
    }

    /// `playlists` maps names (as passed to `url(id:name:)`) to playlist text; it must include "master.m3u8".
    nonisolated init(id: String, playlists: [String: String]) {
        self.playlists = Dictionary(uniqueKeysWithValues: playlists.map { (Self.url(id: id, name: $0.key), Data($0.value.utf8)) })
        self.masterURL = URL(string: Self.url(id: id, name: "master.m3u8"))!
        super.init()
    }

    nonisolated func resourceLoader(
        _ resourceLoader: AVAssetResourceLoader,
        shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest
    ) -> Bool {
        guard let url = loadingRequest.request.url?.absoluteString, let data = playlists[url] else {
            return false
        }
        loadingRequest.contentInformationRequest?.contentType = "public.m3u-playlist"
        loadingRequest.contentInformationRequest?.contentLength = Int64(data.count)
        loadingRequest.contentInformationRequest?.isByteRangeAccessSupported = false
        loadingRequest.dataRequest?.respond(with: data)
        loadingRequest.finishLoading()
        return true
    }
}
