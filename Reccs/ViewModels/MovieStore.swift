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
    
    init() {
        // Load the file you just added to Xcode
        self.films = Bundle.main.decodeMovies("movies.json")
        print("Successfully loaded \(films.count) movie groups.")
    }
}
