//
//  MovieStore.swift
//  Reccs
//
//  Created by Evan Gedrich Pintado on 3/3/26.
//

import Foundation
import Observation

extension Bundle {
    func decodeMovies(_ file: String) -> [MovieEntry] {
        // 1. Locate the file in the bundle
        guard let url = self.url(forResource: file, withExtension: nil) else {
            fatalError("Failed to locate \(file) in bundle.")
        }

        // 2. Load the file into a Data object
        guard let data = try? Data(contentsOf: url) else {
            fatalError("Failed to load \(file) from bundle.")
        }

        // 3. Decode the JSON data into your Swift structs
        let decoder = JSONDecoder()
        do {
            return try decoder.decode([MovieEntry].self, from: data)
        } catch {
            fatalError("Failed to decode \(file): \(error)")
        }
    }
}

@Observable
class MovieStore {
    var films: [MovieEntry] = []
    var isLoading = false
    var errorMessage: String?
    
    private let cloudflareService: CloudflareService
    private let useCloudflare: Bool
    
    /// Initialize with Cloudflare endpoints
    /// - Parameters:
    ///   - d1APIEndpoint: Your Cloudflare D1 API endpoint
    ///   - r2BaseURL: Your Cloudflare R2 bucket base URL
    ///   - useCloudflare: Toggle between Cloudflare and local JSON (useful for development)
    init(d1APIEndpoint: String = "", r2BaseURL: String = "", useCloudflare: Bool = false) {
        self.cloudflareService = CloudflareService(
            d1APIEndpoint: d1APIEndpoint,
            r2BaseURL: r2BaseURL
        )
        self.useCloudflare = useCloudflare
        
        if useCloudflare {
            // Load from Cloudflare asynchronously
            Task {
                await loadMoviesFromCloudflare()
            }
        } else {
            // Load from local JSON synchronously (existing behavior)
            self.films = Bundle.main.decodeMovies("movies.json")
            print("Successfully loaded \(films.count) movies from local JSON.")
        }
    }
    
    /// Load movies from Cloudflare D1
    @MainActor
    func loadMoviesFromCloudflare() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let fetchedMovies = try await cloudflareService.fetchMovies()
            self.films = fetchedMovies
            print("Successfully loaded \(films.count) movies from Cloudflare D1.")
        } catch {
            errorMessage = "Failed to load movies: \(error.localizedDescription)"
            print("Error loading movies from Cloudflare: \(error)")
            
            // Fallback to local JSON if Cloudflare fails
            self.films = Bundle.main.decodeMovies("movies.json")
            print("Fell back to local JSON. Loaded \(films.count) movies.")
        }
        
        isLoading = false
    }
    
    /// Get the poster image URL from R2 for a given movie
    func getPosterURL(for movie: MovieEntry) -> URL? {
        return cloudflareService.getPosterURL(for: movie.id)
    }
    
    /// Refresh movies from Cloudflare
    @MainActor
    func refresh() async {
        guard useCloudflare else { return }
        await loadMoviesFromCloudflare()
    }
}
