//
//  Collections.swift
//  Reccs
//
//  Created by Evan Gedrich Pintado on 3/17/26.
//

import SwiftUI
import Foundation

struct CollectionType: Identifiable, Codable, Hashable {
    var id: String { key }
    var displayColor: Color { Color(hex: color) }
    
    let title: String
    let color: String
    let key: String
}

let collections: [CollectionType] = [
    CollectionType (
        title: "Cultural Feature Films",
        color: "#cf4b48",
        key: "CFF"
    ),
    CollectionType (
        title: "Globalized Feature Films",
        color: "#5e84d6",
        key: "GFF"
    ),
    CollectionType (
        title: "Cultural Short Films",
        color: "#e68e4c",
        key: "CSF"
    )
]
