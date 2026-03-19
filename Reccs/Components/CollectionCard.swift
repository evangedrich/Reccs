//
//  CollectionCard.swift
//  Reccs
//
//  Created by Evan Gedrich Pintado on 3/17/26.
//

import SwiftUI

struct CollectionCard: View {
    let collection: CollectionType
    @Binding var searchText: String
    var onHit: () -> Void
    var body: some View {
        let titleParts = collection.title.split(separator: " ", maxSplits: 1).map(String.init)
        let title1 = titleParts.first ?? ""
        let title2 = titleParts.count > 1 ? titleParts[1] : ""
        Button(action: {
            withAnimation(.easeInOut) {
                searchText = collection.title
                onHit()
            }
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(collection.displayColor)
                    .frame(width: 480, height: 270)
                VStack {
                    Text(title1.uppercased())
                        .font(.system(size: 60, weight: .black))
                        .tracking(-1)
                    Text(title2.uppercased())
                        .font(.system(size: 35, weight: .light))
                        .tracking(5)
                }
            }
        }
        .buttonStyle(.card)
    }
}
