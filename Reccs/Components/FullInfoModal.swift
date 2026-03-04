//
//  FullInfoModal.swift
//  Reccs
//
//  Created by Evan Gedrich Pintado on 3/3/26.
//

import SwiftUI

struct FullInfoModal: View {
    let movie: MovieEntry
    @Binding var isPresented: Bool
    @Namespace private var modalNamespace

    var body: some View {
        ZStack {
            Rectangle().fill(.ultraThinMaterial).ignoresSafeArea()
            
            VStack(spacing: 40) {
                Text(movie.title.original)
                    .font(.title2)
                    .bold()
                
                ScrollView {
                    Text(movie.info)
                        .font(.body)
                        .lineSpacing(4)
                        .multilineTextAlignment(.leading)
                }
                .frame(maxWidth: 1000)
                
                Button("Close") {
                    isPresented = false
                }
                .prefersDefaultFocus(true, in: modalNamespace)
            }
            .padding(100)
            .focusScope(modalNamespace)
        }
    }
}
