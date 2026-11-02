//
//  MovieModels.swift
//  Reccs
//
//  Created by Evan Gedrich Pintado on 3/3/26.
//

import Foundation
import SwiftUI

struct MovieEntry: Identifiable, @unchecked Sendable, Hashable {
    let id: String
    let title: MovieTitle
    let year: String
    let runtime: Int
    let genre: [String]
    let tags: [String]
    let group: MovieGroupDetails
    let info: String
    let watch: [String]
    let trailer: String
    let color: String
    let location: MovieLocation
    /// Optional search titles keyed by service name, for when a service's title can't be found automatically.
    var searchTitles: [String: String]? = nil
}

// Separate nonisolated conformance to Codable
nonisolated extension MovieEntry: Codable {}

struct MovieTitle: Codable, Hashable {
    let original: String
    let transliteration: String?
    let translation: String?
}

struct MovieGroupDetails: Codable, Hashable {
    let people: String?
    let language: String?
    let country: String?
    let location: String?
}

struct MovieLocation: Codable, Hashable {
    let x: Double
    let y: Double
    let name: String
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: 1)
    }
}

extension MovieEntry {
    // Returns the brand name based on the URL string
    func getServiceName(for urlString: String) -> String {
        let url = urlString.lowercased()
        
        if url.contains("kanopy") { return "Kanopy" }
        else if url.contains("netflix") { return "Netflix" }
        else if url.contains("tv.apple") { return "Apple TV" }
        else if url.contains("amazon") || url.contains("primevideo") { return "Prime" }
        else if url.contains("youtu") { return "YouTube" }
        else if url.contains("klassiki") { return "Klassiki" }
        else if url.contains("max.com") || url.contains("hbomax") { return "HBO Max" }
        else if url.contains("tubitv") { return "Tubi" }
        else if url.contains("vimeo") { return "Vimeo" }
        else if url.contains("archive.org") { return "Internet Archive" }
        else if url.contains("hoopla") { return "Hoopla" }
        else if url.contains("fawesome") { return "Fawesome" }
        else if url.contains("mubi") { return "MUBI" }
        else if url.contains("hulu") { return "Hulu" }
        else if url.contains("criterion") { return "Criterion" }
        else if url.contains("fandango") { return "Fandango" }
        else if url.contains("vudu") { return "Vudu" }
        else if url.contains("roku") { return "Roku" }
        else if url.contains("pluto") { return "Pluto TV" }
        else if url.contains("paramount") { return "Paramount+" }
        
        return "Movie"
    }

    // Convenience property for the primary button
    var watchServiceName: String {
        guard let first = watch.first else { return "Movie" }
        return getServiceName(for: first)
    }
}

extension MovieEntry {
    func getServiceColors(for urlString: String) -> (bg: Color, text: Color) {
        let url = urlString.lowercased()
        
        if url.contains("netflix") { return (Color(hex: "101010"), Color(hex: "D12F26")) }
        if url.contains("amazon") || url.contains("primevideo") { return (Color(hex: "3577F6"), .white) }
        if url.contains("youtu") { return (Color(hex: "EA3323"), .white) }
        if url.contains("apple.com") { return (.white, .black) }
        if url.contains("max.com") || url.contains("hbomax") { return (Color(hex: "0047E0"), .white) }
        if url.contains("hulu") { return (Color(hex: "1CE783"), .black) }
        if url.contains("disneyplus") { return (Color(hex: "113CCF"), .white) }
        if url.contains("criterion") { return (Color(hex: "282828"), .white) }
        if url.contains("mubi") { return (Color(hex: "04159F"), .white) }
        if url.contains("kanopy") { return (Color(hex: "111111"), .white) }
        if url.contains("vudu") { return (Color(hex: "3178ff"), .white) }
        if url.contains("fandango") { return (Color(hex: "EE7B30"), Color(hex: "4676BB")) }
        if url.contains("tubi") { return (Color(hex: "5136A4"), Color(hex: "FCF75F")) }
        if url.contains("hoopla") { return (Color(hex: "51ABE4"), .white) }
        if url.contains("vimeo") { return (Color(hex: "62AFD7"), .white) }
        if url.contains("fawesome") { return (Color(hex: "EA3323"), .white) }
        if url.contains("pluto") { return (.black, .yellow) }
        if url.contains("paramount") { return (Color(hex: "2962F6"), .white) }
        
        return (Color.black.opacity(0.8), .white)
    }
}

extension MovieEntry {
    var regionLabel: String {
        let code = String(id.prefix(4)).uppercased()
        return SubregionNames[code] ?? ""
    }
}

extension MovieEntry {
    /// Sort key for region pages: CFF, then GFF, then CSF, and in ID order within each type.
    /// IDs are the four-letter region, the three-letter type, then an optional number.
    var regionPageOrder: String {
        let type = id.dropFirst(4).prefix(3)
        let rank = ["CFF", "GFF", "CSF"].firstIndex(of: String(type)) ?? 3
        return "\(rank)\(id)"
    }
}

/// Shuffles the home page rows into a new order each day, the same order all day.
nonisolated enum DailyShuffle {
    static var todaySeed: UInt64 {
        let date = Calendar.current.dateComponents([.year, .month, .day], from: .now)
        return UInt64(date.year ?? 0) * 10_000 + UInt64(date.month ?? 0) * 100 + UInt64(date.day ?? 0)
    }

    static func order(_ movies: [MovieEntry], seed: UInt64) -> [MovieEntry] {
        // Sorted first so the result doesn't depend on the order the database returned them in.
        var generator = SplitMix64(state: seed)
        return movies.sorted { $0.id < $1.id }.shuffled(using: &generator)
    }

    /// A repeatable generator; Swift's own is deliberately different on every run.
    private struct SplitMix64: RandomNumberGenerator {
        var state: UInt64

        mutating func next() -> UInt64 {
            state &+= 0x9E37_79B9_7F4A_7C15
            var z = state
            z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
            z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
            return z ^ (z >> 31)
        }
    }
}
