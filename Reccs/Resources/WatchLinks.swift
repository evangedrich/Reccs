//
//  WatchLinks.swift
//  Reccs
//
//  Opens a movie's streaming link in the right app. tvOS only reports whether a URL opened, not where
//  it landed, so each service's route below records what was verified on a real Apple TV (Oct 2026).
//

import Foundation
import UIKit

/// How to reach a service from this app.
nonisolated struct WatchRoute {
    /// URLs that land on the movie itself, best first.
    var direct: [URL] = []
    /// Opens the service's app without reaching the movie; also how we detect that it's installed.
    var app: URL?
    /// Opens the app's search for a title, where the app supports it.
    var search: ((String) -> URL?)?
    var appStoreID: Int?
    /// The app has no link other apps can use (or detect), so the App Store page is the way in:
    /// it shows Open when the app is installed and Get when it isn't.
    var reachableOnlyViaAppStore = false

    init(link: String) {
        let lowercased = link.lowercased()
        let url = URL(string: link)
        let path = url?.path ?? ""
        let web = url.map { [$0] } ?? []

        if lowercased.contains("amazon.com") || lowercased.contains("primevideo.com") {
            appStoreID = 545519333
            app = URL(string: "aiv://")
            search = { title in
                title.urlQueryEscaped.flatMap { URL(string: "aiv://aiv/search?phrase=\($0)") }
            }
            let marker = link.contains("/dp/") ? "/dp/" : "/detail/"
            if let id = link.components(separatedBy: marker).dropFirst().first?.components(separatedBy: CharacterSet(charactersIn: "/?")).first {
                let key = id.hasPrefix("amzn1.") ? "gti" : "asin"
                direct = [URL(string: "aiv://aiv/detail?\(key)=\(id)")].compactMap { $0 }
            }
        } else if lowercased.contains("youtu.be") || lowercased.contains("youtube.com") {
            appStoreID = 544007664
            app = URL(string: "youtube://")
            if let id = TrailerReference(link)?.videoID {
                direct = [URL(string: "youtube://www.youtube.com/watch?v=\(id)")].compactMap { $0 }
            }
        } else if lowercased.contains("tv.apple.com") {
            direct = web
        } else if lowercased.contains("max.com") {
            appStoreID = 1666653815
            if let id = path.split(separator: "/").last {
                direct = [URL(string: "https://play.hbomax.com/movie/\(id)")].compactMap { $0 }
            }
        } else if lowercased.contains("tubitv.com") {
            appStoreID = 886445756
            app = URL(string: "tubitv://")
            let parts = path.split(separator: "/")
            if parts.count >= 2 {
                direct = [URL(string: "tubitv://media-details?contentType=movie&contentId=\(parts[1])")].compactMap { $0 }
            }
        } else if lowercased.contains("netflix.com") {
            // Netflix and Hulu can only be judged on a TV that passes their household checks, which the
            // test device didn't. These links open the apps there, but reaching the movie is unconfirmed.
            appStoreID = 363590051
            app = URL(string: "nflx://")
            if let id = path.split(separator: "/").last {
                direct = [
                    URL(string: "https://www.netflix.com/title/\(id)"),
                    URL(string: "nflx://www.netflix.com/title/\(id)"),
                ].compactMap { $0 }
            }
        } else if lowercased.contains("hulu.com") {
            appStoreID = 376510438
            app = URL(string: "hulu://")
            // Movie links end in the ID: /movie/the-title-<uuid>.
            if let id = UUID(uuidString: String(path.suffix(36)))?.uuidString.lowercased() {
                direct = [
                    URL(string: "https://www.hulu.com/watch/\(id)"),
                    URL(string: "hulu://watch/\(id)"),
                ].compactMap { $0 }
            }
        } else if lowercased.contains("vimeo.com") {
            // These apps ignore the movie path today, but keeping it means they'd start working if that changes.
            appStoreID = 425194759
            app = URL(string: "vimeo://vimeo.com\(path)")
        } else if lowercased.contains("mubi.com") {
            appStoreID = 626148774
            app = URL(string: "mubi://mubi.com\(path)")
        } else if lowercased.contains("criterionchannel.com") {
            appStoreID = 1454275199
            app = URL(string: "criterion://www.criterionchannel.com\(path)")
        } else if lowercased.contains("kanopy.com") {
            appStoreID = 1205614510
            reachableOnlyViaAppStore = true
        } else if lowercased.contains("hoopladigital.com") {
            appStoreID = 580643740
            reachableOnlyViaAppStore = true
        } else if lowercased.contains("klassiki") {
            appStoreID = 6443582823
            reachableOnlyViaAppStore = true
        } else if lowercased.contains("fawesome.tv") {
            appStoreID = 1063891742
            reachableOnlyViaAppStore = true
        } else if lowercased.contains("fandango.com") {
            // Fandango, Paramount+ and Pluto TV weren't installed on the test device, so these are unverified.
            appStoreID = 487285735
            app = URL(string: "vudu://")
            direct = web
        } else if lowercased.contains("paramount") {
            appStoreID = 530168168
            app = URL(string: "pplus://")
            direct = web
        } else if lowercased.contains("pluto") {
            appStoreID = 751712884
            direct = web
        } else {
            // No tvOS app known (Internet Archive, The Roku Channel, ...): only a universal link could work.
            direct = web
        }
    }

    var appStoreURLs: [URL] {
        guard let appStoreID else { return [] }
        return [
            URL(string: "com.apple.TVAppStore://itunes.apple.com/app/id\(appStoreID)"),
            URL(string: "https://apps.apple.com/us/app/id\(appStoreID)"),
        ].compactMap { $0 }
    }
}

/// An alert to show before (or instead of) leaving the app.
struct WatchAlert: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    /// Label for the button that continues, and the URLs it tries in order. Nil for a dead end.
    var action: (label: String, urls: [URL])?
    var serviceName: String

    static func unavailable(_ serviceName: String) -> WatchAlert {
        WatchAlert(
            title: "\(serviceName) Unavailable",
            message: "\(serviceName) can't be opened on this Apple TV right now.",
            serviceName: serviceName
        )
    }
}

@MainActor
enum WatchLinkOpener {
    /// Tries to reach the movie, returning an alert when the user needs to be told something first.
    static func open(_ link: String, for movie: MovieEntry) async -> WatchAlert? {
        let route = WatchRoute(link: link)
        let serviceName = movie.getServiceName(for: link)

        if await openFirst(route.direct) {
            return nil
        }

        if let app = route.app, UIApplication.shared.canOpenURL(app) {
            let title = await SearchTitle.resolve(link, for: movie)
            let urls = [route.search?(title), app].compactMap { $0 }
            return WatchAlert(
                title: "Search in \(serviceName)",
                message: "We can't link directly to this movie in \(serviceName). Search for “\(title)” there.",
                action: ("Open \(serviceName)", urls),
                serviceName: serviceName
            )
        }

        if route.reachableOnlyViaAppStore {
            let title = await SearchTitle.resolve(link, for: movie)
            return WatchAlert(
                title: "Open \(serviceName)",
                message: "We can't link directly to this movie in \(serviceName). On the next screen, choose Open (or Get if you don't have the app yet), then search for “\(title)”.",
                action: ("Continue", route.appStoreURLs),
                serviceName: serviceName
            )
        }

        if await openFirst(route.appStoreURLs) {
            return nil
        }
        return .unavailable(serviceName)
    }

    /// Runs an alert's action, returning a follow-up alert if nothing opened.
    static func perform(_ alert: WatchAlert) async -> WatchAlert? {
        guard let action = alert.action else { return nil }
        return await openFirst(action.urls) ? nil : .unavailable(alert.serviceName)
    }

    private static func openFirst(_ urls: [URL]) async -> Bool {
        for url in urls where await UIApplication.shared.open(url) {
            return true
        }
        return false
    }
}

/// Finds the title a service itself uses, since it often differs from ours
/// ("Three Colors: White" vs "Three Colours: White", "Atanarjuat: The Fast Runner" vs "The Fast Runner").
@MainActor
enum SearchTitle {
    private static var cache: [String: String] = [:]

    /// The page `<title>` wrapper for each service; only an exact match is trusted.
    private static let pageTitleFormats: [(service: String, prefix: String, suffix: String)] = [
        ("Netflix", "Watch ", " | Netflix"),
        ("Hulu", "Watch ", " Streaming Online | Hulu"),
        ("Vimeo", "Watch ", " Online | Vimeo On Demand on Vimeo"),
        ("Hoopla", "", " Movie | hoopla"),
        ("Fawesome", "Watch ", " Full Movie Free Online - Fawesome TV"),
        ("MUBI", "Watch ", " on MUBI"),
        ("Criterion", "", " | Criterion Channel"),
        ("Klassiki", "", " - Klassiki"),
        ("Fandango", "", " | Stream on Fandango (Vudu)"),
        ("Apple TV", "", " - Apple TV"),
        ("HBO Max", "Watch ", " | HBO Max"),
        ("Tubi", "Watch ", " - Free Movies | Tubi"),
    ]

    /// Loads ahead of time the titles the search alert would need, so it appears without delay.
    static func prefetch(for movie: MovieEntry) async {
        for link in movie.watch where !link.isEmpty && WatchRoute(link: link).direct.isEmpty {
            _ = await resolve(link, for: movie)
        }
    }

    /// In order: a curated override, this service's page, another service's page for the same movie, our own title.
    static func resolve(_ link: String, for movie: MovieEntry) async -> String {
        if let override = movie.searchTitles?[movie.getServiceName(for: link)] {
            return override
        }
        if let cached = cache[link] {
            return cached
        }
        let others = movie.watch.filter { $0 != link && !$0.isEmpty }
        for candidate in [link] + others.prefix(2) {
            if let title = await pageTitle(of: candidate, service: movie.getServiceName(for: candidate)) {
                cache[link] = title
                return title
            }
        }
        return movie.title.translation ?? movie.title.transliteration ?? movie.title.original
    }

    private static func pageTitle(of link: String, service: String) async -> String? {
        guard let format = pageTitleFormats.first(where: { $0.service == service }),
              let url = URL(string: link) else { return nil }
        var request = URLRequest(url: url, timeoutInterval: 3)
        request.setValue(
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Safari/605.1.15",
            forHTTPHeaderField: "User-Agent"
        )
        guard let (data, _) = try? await URLSession.shared.data(for: request) else { return nil }
        return title(inPage: String(decoding: data, as: UTF8.self), prefix: format.prefix, suffix: format.suffix)
    }

    private static func title(inPage html: String, prefix: String, suffix: String) -> String? {
        guard let open = html.range(of: "<title"),
              let start = html[open.upperBound...].range(of: ">")?.upperBound,
              let end = html[start...].range(of: "</title>")?.lowerBound else { return nil }
        var text = String(html[start..<end])
            .replacingOccurrences(of: "\u{00A0}", with: " ")
            .replacingOccurrences(of: "\u{200E}", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if text.contains("&") {
            text = decodingHTMLEntities(text)
        }
        guard text.hasPrefix(prefix), text.hasSuffix(suffix),
              text.count > prefix.count + suffix.count else { return nil }
        text = String(text.dropFirst(prefix.count).dropLast(suffix.count))
        if let year = text.range(of: #"\s*\(\d{4}\)$"#, options: .regularExpression) {
            text.removeSubrange(year)
        }
        return text.isEmpty ? nil : text
    }
}

/// Page titles arrive HTML-escaped ("for&ecirc;t", "&ndash;").
private func decodingHTMLEntities(_ text: String) -> String {
    let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
        .documentType: NSAttributedString.DocumentType.html,
        .characterEncoding: String.Encoding.utf8.rawValue,
    ]
    guard let data = text.data(using: .utf8),
          let decoded = try? NSAttributedString(data: data, options: options, documentAttributes: nil) else { return text }
    return decoded.string.trimmingCharacters(in: .whitespacesAndNewlines)
}

private extension String {
    nonisolated var urlQueryEscaped: String? {
        addingPercentEncoding(withAllowedCharacters: .alphanumerics)
    }
}
