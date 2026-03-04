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
    var watchURL: URL? {
        guard let webURL = watch.first else { return nil }
        
        var finalURLString = webURL
        
        if webURL.contains("kanopy.com") {
            finalURLString = webURL.replacingOccurrences(of: "https://", with: "kanopy://")
        } else if webURL.contains("netflix.com") {
            finalURLString = webURL.replacingOccurrences(of: "https://", with: "nflx://")
        } else if webURL.contains("tv.apple.com") {
            finalURLString = webURL.replacingOccurrences(of: "https://", with: "videos://")
        } else if webURL.contains("amazon.com") || webURL.contains("primevideo.com") {
            finalURLString = webURL.replacingOccurrences(of: "https://", with: "primevideo://")
        } else if webURL.contains("youtu.be") || webURL.contains("youtube.com") {
            finalURLString = webURL.replacingOccurrences(of: "https://", with: "youtube://")
        } else if webURL.contains("max.com") || webURL.contains("hbomax.com") {
            finalURLString = webURL.replacingOccurrences(of: "https://", with: "max://")
        } else if webURL.contains("tubitv.com") {
            finalURLString = webURL.replacingOccurrences(of: "https://", with: "tubitv://")
        } else if webURL.contains("vimeo.com") {
            finalURLString = webURL.replacingOccurrences(of: "https://", with: "vimeo://")
        } else if webURL.contains("mubi.com") {
            finalURLString = webURL.replacingOccurrences(of: "https://", with: "mubi://")
        } else if webURL.contains("hulu.com") {
            finalURLString = webURL.replacingOccurrences(of: "https://", with: "hulu://")
        } else if webURL.contains("criterionchannel.com") {
            finalURLString = webURL.replacingOccurrences(of: "https://", with: "vhx-criterion-channel://")
        } else if webURL.contains("vudu.com") || webURL.contains("fandangoathome.com") {
            finalURLString = webURL.replacingOccurrences(of: "https://", with: "vudu://")
        } else if webURL.contains("therokuchannel.roku.com") {
            finalURLString = webURL.replacingOccurrences(of: "https://", with: "roku://")
        }
        
        // Note: Klassiki, Internet Archive, Hoopla, and Fawesome TV
        // typically rely on standard Universal Links (https://) for tvOS.
        
        return URL(string: finalURLString)
    }
}

extension MovieEntry {
    // Returns the brand name based on the URL string
    var watchServiceName: String {
        guard let url = watch.first?.lowercased() else { return "Movie" }
        
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
        else if url.contains("fandango") || url.contains("vudu") { return "Fandango" }
        else if url.contains("roku") { return "Roku" }
        
        return "Movie" // Default fallback
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
