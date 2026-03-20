//
//  ProviderListView.swift
//  Reccs
//
//  Created by Evan Gedrich Pintado on 3/5/26.
//

import SwiftUI

struct ProviderListView: View {
    let movie: MovieEntry
    @Binding var isPresented: Bool
    @Binding var showInstallAlert: Bool
    @Binding var failedServiceName: String
    
    var body: some View {
        VStack(spacing: 40) {
            Text("Where to Watch")
                .font(.headline)
                .padding(.top, 48)
            
            ScrollView {
                VStack(spacing: 20) {
                    ForEach(Array(movie.watch.enumerated()), id: \.offset) { index, urlString in
                        let serviceName = movie.getServiceName(for: urlString)
                        let brandColors = movie.getServiceColors(for: urlString)
                        
                        Button(action: {
                            if let url = movie.getWatchURL(for: urlString) {
                                UIApplication.shared.open(url, options: [:]) { success in
                                    if !success {
                                        self.failedServiceName = serviceName
                                        self.isPresented = false
                                        self.showInstallAlert = true
                                    }
                                }
                            }
                        }) {
                            HStack(spacing: 20) {
                                Text(serviceName)
                                    .font(.caption2.bold())
                                    .foregroundColor(brandColors.text)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .frame(width: 192, height: 108)
                                    .background(brandColors.bg)
                                    .cornerRadius(10)
                                
                                Text("Open in \(serviceName)")
                                    .font(.body)
                                    .lineLimit(1)
                                    .allowsTightening(true)
                                    .minimumScaleFactor(0.8)
                                Spacer()
                            }
                            .padding()
                        }
                        .buttonStyle(.card)
                    }
                }
                .padding(.horizontal, 40)
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
        }
        .frame(width: 750, height: 550)
//        .background(.ultraThinMaterial)
//        .overlay(
//            RoundedRectangle(cornerRadius: 40)
//                .stroke(.white.opacity(0.2), lineWidth: 1)
//        )
    }
}
