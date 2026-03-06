//
//  MovieModels.swift
//  Reccs
//
//  Created by Evan Gedrich Pintado on 3/3/26.
//

import Foundation
import SwiftUI

struct MovieEntry: Identifiable, Codable, Hashable {
    let id: String
    let title: MovieTitle
    let year: String
    let runtime: Int
    let genre: [String]
    let group: MovieGroupDetails
    let info: String
    let watch: [String]
    let trailer: String
    let color: String
    let location: MovieLocation
}

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
    func getWatchURL(for webURL: String) -> URL? {
        let finalURLString = webURL
        if webURL.contains("amazon.com") || webURL.contains("primevideo.com") {
            if let id = webURL.components(separatedBy: "/detail/").last?.components(separatedBy: "/").first {
                return URL(string: "aiv://aiv/play?asin=\(id)")
            }
        } else if webURL.contains("youtu.be") || webURL.contains("youtube.com") {
            let id = webURL.contains("youtu.be/") ?
                webURL.components(separatedBy: "youtu.be/").last?.components(separatedBy: "?").first :
                URLComponents(string: webURL)?.queryItems?.first(where: { $0.name == "v" })?.value
            if let id = id { return URL(string: "youtube://watch/\(id)") }
        } else if webURL.contains("max.com") {
            let id = webURL.components(separatedBy: "/").last?.components(separatedBy: "?").first
            if let id = id { return URL(string: "https://play.max.com/movie/\(id)") }
        } else if webURL.contains("kanopy.com") {
            let id = webURL.components(separatedBy: "/").last?.components(separatedBy: "?").first
            if let id = id { return URL(string: "https://www.kanopy.com/product/\(id)") }
        }
        return URL(string: finalURLString)
    }

    var watchURL: URL? {
        guard let first = watch.first else { return nil }
        return getWatchURL(for: first)
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
        else if url.contains("max.com") || url.contains("hbomax") { return "Max" }
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
        
        return (Color.black.opacity(0.8), .white)
    }
}

extension MovieEntry {
    var regionLabel: String {
        let code = String(id.prefix(4)).uppercased()
        
        switch code {
        case "AFNO": return "North Africa"
        case "AFEA": return "East Africa"
        case "AFSO": return "Southern Africa"
        case "AFCE": return "Central Africa"
        case "AFWE": return "West Africa"
        case "AMNO": return "Northern North America"
        case "AMEA": return "Eastern North America"
        case "AMSW": return "Southwest North America"
        case "AMNW": return "Northwest North America"
        case "AMIN": return "Interior North America"
        case "AMCE": return "Central America"
        case "AMCR": return "Caribbean"
        case "AMHI": return "Highland South America"
        case "AMLO": return "Lowland South America"
        case "AMSO": return "Southern South America"
        case "ASNO": return "North Asia"
        case "ASEA": return "East Asia"
        case "ASSE": return "Southeast Asia"
        case "ASHI": return "Highland Asia"
        case "ASSO": return "South Asia"
        case "ASWE": return "West Asia"
        case "ASCE": return "Central Asia"
        case "ASIN": return "Inner Asia"
        case "EUEA": return "Eastern Europe"
        case "EUWE": return "Western Europe"
        case "OCAU": return "Australia"
        case "OCMD": return "Madagascar"
        case "OCML": return "Melanesia"
        case "OCMC": return "Micronesia"
        case "OCPL": return "Polynesia"
        default: return "" // Fallback for unknown codes
        }
    }
}
