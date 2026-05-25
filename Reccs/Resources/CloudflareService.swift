//
//  CloudflareService.swift
//  Reccs
//
//  Network service for fetching movie data from Cloudflare D1 and R2
//

import Foundation

enum CloudflareError: Error {
    case invalidURL
    case invalidResponse
    case decodingError(Error)
    case networkError(Error)
}

actor CloudflareService {
    // Replace these with your actual Cloudflare endpoints
    private let d1APIEndpoint: String
    private let r2BaseURL: String
    
    init(d1APIEndpoint: String, r2BaseURL: String) {
        self.d1APIEndpoint = d1APIEndpoint
        self.r2BaseURL = r2BaseURL
    }
    
    /// Fetch all movies from Cloudflare D1 database
    func fetchMovies() async throws -> [MovieEntry] {
        guard let url = URL(string: d1APIEndpoint) else {
            throw CloudflareError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw CloudflareError.invalidResponse
            }
            
            let decoder = JSONDecoder()
            let movies = try decoder.decode([MovieEntry].self, from: data)
            return movies
            
        } catch let error as DecodingError {
            throw CloudflareError.decodingError(error)
        } catch {
            throw CloudflareError.networkError(error)
        }
    }
    
    /// Get the R2 URL for a movie poster image
    func getPosterURL(for movieID: String) -> URL? {
        // Images are stored in /posters/ directory as WebP format
        return URL(string: "\(r2BaseURL)/posters/\(movieID).webp")
    }
    
    /// Fetch a specific movie by ID from D1
    func fetchMovie(id: String) async throws -> MovieEntry? {
        guard let url = URL(string: "\(d1APIEndpoint)/\(id)") else {
            throw CloudflareError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw CloudflareError.invalidResponse
            }
            
            let decoder = JSONDecoder()
            let movie = try decoder.decode(MovieEntry.self, from: data)
            return movie
            
        } catch let error as DecodingError {
            throw CloudflareError.decodingError(error)
        } catch {
            throw CloudflareError.networkError(error)
        }
    }
}
