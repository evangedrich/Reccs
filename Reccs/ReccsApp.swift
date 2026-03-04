//
//  ReccsApp.swift
//  Reccs
//
//  Created by Evan Gedrich Pintado on 2/13/26.
//

import SwiftUI

@main
struct ReccsApp: App {
    @State private var movieStore = MovieStore()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(movieStore)
        }
    }
}
