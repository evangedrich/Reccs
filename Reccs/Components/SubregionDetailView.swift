//
//  SubregionDetailView.swift
//  Reccs
//
//  Created by Evan Gedrich Pintado on 3/10/26.
//

import SwiftUI

struct SubregionDetailView: View {
    let id: String
    let dismiss: () -> Void
    var body: some View {
        ZStack {
            Color(hex: "#181818").ignoresSafeArea()
            
            VStack(spacing: 40) {
                Text(SubregionNames[id] ?? id)
                    .font(.system(size: 60))
                    .frame(height: 60)
                    .fontWeight(.heavy)
                Text(SubregionDescriptions[id] ?? id)
                    .font(.body)
                    .multilineTextAlignment(.center)
                Button(action: dismiss) {
                    Text("Back to Map")
                }
            }
            .frame(width: 1000)
        }
    }
}
