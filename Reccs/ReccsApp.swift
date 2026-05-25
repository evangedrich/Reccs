//
//  ReccsApp.swift
//  Reccs
//
//  Created by Evan Gedrich Pintado on 2/13/26.
//

import SwiftUI

@main
struct ReccsApp: App {
    @State private var movieStore = MovieStore(
        d1APIEndpoint: CloudflareConfig.d1APIEndpoint,
        r2BaseURL: CloudflareConfig.r2BaseURL,
        useCloudflare: CloudflareConfig.useCloudflare
    )
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(movieStore)
        }
    }
}
