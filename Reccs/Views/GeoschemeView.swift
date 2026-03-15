//
//  GeoschemeView.swift
//  Reccs
//
//  Created by Evan Gedrich Pintado on 3/7/26.
//

import SwiftUI

struct GeoschemeView: View {
    @FocusState private var focusedSubregion: String?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 10) {
                //Text(focusedSubregion != nil ? (SubregionNames[focusedSubregion!] ?? "") : "Select a subregion")
                    //.font(.system(size: 34))
                    //.frame(height: 32)
                ZStack {
                    // LAYER 1: Complete Background Map
                    MapPaths()

                    // LAYER 2: Illuminated Subregion Dots Path
                    if let id = focusedSubregion {
                        PulsingSubregion(subregionView: AnyView(viewForSubregion(id))) // viewForSubregion(id) only without pulse
                            .frame(width: 1440, height: 720) // Matches the base map size
                            .brightness(1) // Makes the dots "light up"
                            // .shadow(color: .white.opacity(0.4), radius: 3) // The illuminated glow
                            .id(id) // Helps SwiftUI track the change for animation
                    }

                    // LAYER 3: Invisible Focus Targets
                    Group {
                        focusSubregion(id: "AFNO", x: 725, y: 240)
                        focusSubregion(id: "AFEA", x: 830, y: 350)
                        focusSubregion(id: "AFSO", x: 780, y: 480)
                        focusSubregion(id: "AFCE", x: 740, y: 380)
                        focusSubregion(id: "AFWE", x: 640, y: 320)
                    }

                    Group {
                        focusSubregion(id: "AMNO", x: 350, y: 150)
                        focusSubregion(id: "AMEA", x: 420, y: 280)
                        focusSubregion(id: "AMSW", x: 280, y: 320)
                        focusSubregion(id: "AMNW", x: 220, y: 220)
                        focusSubregion(id: "AMIN", x: 330, y: 240)
                        focusSubregion(id: "AMCE", x: 380, y: 400)
                        focusSubregion(id: "AMCR", x: 450, y: 380)
                        focusSubregion(id: "AMHI", x: 430, y: 500)
                        focusSubregion(id: "AMLO", x: 520, y: 480)
                        focusSubregion(id: "AMSO", x: 480, y: 620)
                    }

                    Group {
                        focusSubregion(id: "ASNO", x: 1000, y: 150)
                        focusSubregion(id: "ASEA", x: 1150, y: 300)
                        focusSubregion(id: "ASSE", x: 1100, y: 450)
                        focusSubregion(id: "ASHI", x: 1050, y: 350)
                        focusSubregion(id: "ASSO", x: 950, y: 400)
                        focusSubregion(id: "ASWE", x: 850, y: 300)
                        focusSubregion(id: "ASCE", x: 950, y: 250)
                        focusSubregion(id: "ASIN", x: 1000, y: 280)
                        focusSubregion(id: "EUEA", x: 850, y: 180)
                        focusSubregion(id: "EUWE", x: 750, y: 200)
                    }

                    Group {
                        focusSubregion(id: "OCAU", x: 1200, y: 550)
                        focusSubregion(id: "OCMD", x: 880, y: 520)
                        focusSubregion(id: "OCML", x: 1300, y: 500)
                        focusSubregion(id: "OCMC", x: 1250, y: 420)
                        focusSubregion(id: "OCPL", x: 1350, y: 450)
                    }
                    
                    Group {
                        focusSubregion(id: "PORTAL_WEST", x: 290, y: 550)
                        focusSubregion(id: "PORTAL_EAST", x: 1540, y: 360)
                    }
                }
                .frame(width: 1440, height: 720)
            }
            .scaleEffect(1.1)
            .navigationDestination(for: String.self) { id in
                SubregionDetailView(id: id)
            }
            .onChange(of: focusedSubregion) { oldValue, newValue in
                if newValue == "PORTAL_WEST" {
                    focusedSubregion = "OCPL"
                } else if newValue == "PORTAL_EAST" {
                    focusedSubregion = "AMHI"
                }
            }
        }
        }
    @ViewBuilder
    private func focusSubregion(id: String, x: CGFloat, y: CGFloat) -> some View {
        // Purely invisible focus target
        NavigationLink(value: id) {
            Color.clear
                .frame(width: 140, height: 140) // The area the remote "grabs"
                // .border(Color.red, width: 2) // border to see focus areas for debugging
                .contentShape(Rectangle())    // Makes the clear area focusable
                .focusable()
        }
        .buttonStyle(GhostButtonStyle())
        .focusEffectDisabled()
        .focused($focusedSubregion, equals: id)
        .position(x: x, y: y)
    }
    @ViewBuilder
    func viewForSubregion(_ id: String) -> some View {
        switch id {
        case "AFNO": MapPaths.AFNO()
        case "AFEA": MapPaths.AFEA()
        case "AFSO": MapPaths.AFSO()
        case "AFCE": MapPaths.AFCE()
        case "AFWE": MapPaths.AFWE()
        case "AMNO": MapPaths.AMNO()
        case "AMEA": MapPaths.AMEA()
        case "AMSW": MapPaths.AMSW()
        case "AMNW": MapPaths.AMNW()
        case "AMIN": MapPaths.AMIN()
        case "AMCE": MapPaths.AMCE()
        case "AMCR": MapPaths.AMCR()
        case "AMHI": MapPaths.AMHI()
        case "AMLO": MapPaths.AMLO()
        case "AMSO": MapPaths.AMSO()
        case "ASNO": MapPaths.ASNO()
        case "ASEA": MapPaths.ASEA()
        case "ASSE": MapPaths.ASSE()
        case "ASHI": MapPaths.ASHI()
        case "ASSO": MapPaths.ASSO()
        case "ASWE": MapPaths.ASWE()
        case "ASCE": MapPaths.ASCE()
        case "ASIN": MapPaths.ASIN()
        case "EUEA": MapPaths.EUEA()
        case "EUWE": MapPaths.EUWE()
        case "OCAU": MapPaths.OCAU()
        case "OCMD": MapPaths.OCMD()
        case "OCML": MapPaths.OCML()
        case "OCMC": MapPaths.OCMC()
        case "OCPL": MapPaths.OCPL()
        default: EmptyView()
        }
    }
}

struct PulsingSubregion: View {
    let subregionView: AnyView
    @State private var pulseAlpha: Double = 0.1

    var body: some View {
        subregionView
            .brightness(1)
            .shadow(color: .white.opacity(pulseAlpha), radius: 2)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.3).repeatForever(autoreverses: true)) {
                    pulseAlpha = 0.4
                }
            }
    }
}

struct GhostButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}
