//
//  MovieCardSkeleton.swift
//  Reccs
//
//  Loading placeholder for MovieCard
//

import SwiftUI

struct MovieCardSkeleton: View {
    @State private var shimmerOffset: CGFloat = -1
    
    var body: some View {
        ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.2))
                .frame(width: 300, height: 400)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.clear,
                                    Color.white.opacity(0.3),
                                    Color.clear
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .offset(x: shimmerOffset * 600)
                )
                .clipped()
            
            VStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 200, height: 20)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 80, height: 14)
            }
            .padding()
            .frame(width: 300)
            .background(
                LinearGradient(
                    colors: [Color.gray.opacity(0.4), Color.gray.opacity(0.2), .clear],
                    startPoint: .bottom,
                    endPoint: .top
                )
                .cornerRadius(12)
            )
        }
        .onAppear {
            withAnimation(
                Animation.linear(duration: 1.5)
                    .repeatForever(autoreverses: false)
            ) {
                shimmerOffset = 1
            }
        }
    }
}

#Preview {
    HStack(spacing: 50) {
        MovieCardSkeleton()
        MovieCardSkeleton()
        MovieCardSkeleton()
    }
    .background(Color.black)
}
