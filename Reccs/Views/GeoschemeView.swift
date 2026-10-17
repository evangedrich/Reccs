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
                        focusSubregion(id: "AFNO", x: 715, y: 225, width: 80, height: 40)
                        focusSubregion(id: "AFNE", x: 869, y: 341, width: 97, height: 53)
                        focusSubregion(id: "AFEA", x: 829, y: 432, width: 86, height: 48)
                        focusSubregion(id: "AFSO", x: 795, y: 550, width: 65, height: 55)
                        focusSubregion(id: "AFCE", x: 750, y: 450, width: 56, height: 101)
                        focusSubregion(id: "AFWE", x: 667, y: 379, width: 61, height: 148)
                        focusSubregion(id: "AFNC", x: 753, y: 358, width: 40, height: 45)
                    }

                    Group {
                        focusSubregion(id: "AMNO", x: 437, y: 53, width: 259, height: 40)
                        focusSubregion(id: "AMEA", x: 446, y: 200, width: 100, height: 127)
                        focusSubregion(id: "AMSW", x: 267, y: 257, width: 160, height: 64)
                        focusSubregion(id: "AMNW", x: 256, y: 164, width: 139, height: 105)
                        focusSubregion(id: "AMIN", x: 358, y: 135, width: 50, height: 107)
                        focusSubregion(id: "AMCE", x: 330, y: 369, width: 72, height: 116)
                        focusSubregion(id: "AMCR", x: 493, y: 340, width: 71, height: 71)
                        focusSubregion(id: "AMWE", x: 412, y: 468, width: 118, height: 55)
                        focusSubregion(id: "AMNE", x: 517, y: 445, width: 60, height: 55)
                        focusSubregion(id: "AMSO", x: 494, y: 601, width: 132, height: 132)
                    }

                    Group {
                        focusSubregion(id: "ASNO", x: 1091, y: 57, width: 190, height: 79)
                        focusSubregion(id: "ASEA", x: 1205, y: 229, width: 149, height: 57)
                        focusSubregion(id: "ASSE", x: 1152, y: 300, width: 81, height: 49)
                        focusSubregion(id: "ASHI", x: 1061, y: 248, width: 44, height: 40)
                        focusSubregion(id: "ASSO", x: 1042, y: 354, width: 124, height: 152)
                        focusSubregion(id: "ASSW", x: 989, y: 228, width: 63, height: 54)
                        focusSubregion(id: "ASWE", x: 872, y: 262, width: 139, height: 57)
                        focusSubregion(id: "ASCE", x: 975, y: 151, width: 91, height: 40)
                        focusSubregion(id: "ASIN", x: 1102, y: 149, width: 126, height: 75)
                        focusSubregion(id: "EUEA", x: 875, y: 140, width: 64, height: 147)
                        focusSubregion(id: "EUWE", x: 732, y: 120, width: 156, height: 150)
                    }

                    Group {
                        focusSubregion(id: "OCAU", x: 1227, y: 549, width: 138, height: 83)
                        focusSubregion(id: "OCMD", x: 860, y: 565, width: 43, height: 58)
                        focusSubregion(id: "OCMR", x: 1164, y: 403, width: 81, height: 121)
                        focusSubregion(id: "OCML", x: 1277, y: 444, width: 125, height: 68)
                        focusSubregion(id: "OCMC", x: 1287, y: 343, width: 82, height: 67)
                        focusSubregion(id: "OCPL", x: 1391, y: 436, width: 52, height: 157)
                    }
                    
                    Group {
                        focusSubregion(id: "PORTAL_WEST", x: 258, y: 471, width: 54, height: 156)
                        focusSubregion(id: "PORTAL_EAST", x: 1554, y: 367, width: 80, height: 132)
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
                    focusedSubregion = "AMWE"
                }
            }
        }
        }
    @ViewBuilder
    private func focusSubregion(id: String, x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) -> some View {
        // Purely invisible focus target
        NavigationLink(value: id) {
            Color.clear
                .frame(width: width, height: height) // The area the remote "grabs"
                // .border(Color.red, width: 2) // border to see focus areas for debugging
                .contentShape(Rectangle())    // Makes the clear area focusable
                .focusable()
        }
        .buttonStyle(GhostButtonStyle())
        .focusEffectDisabled()
        .focused($focusedSubregion, equals: id)
        .accessibilityIdentifier("region-\(id)")
        .position(x: x, y: y)
    }
    @ViewBuilder
    func viewForSubregion(_ id: String) -> some View {
        switch id {
        case "AFNO": MapPaths.AFNO()
        case "AFNE": MapPaths.AFNE()
        case "AFEA": MapPaths.AFEA()
        case "AFSO": MapPaths.AFSO()
        case "AFCE": MapPaths.AFCE()
        case "AFWE": MapPaths.AFWE()
        case "AFNC": MapPaths.AFNC()
        case "AMNO": MapPaths.AMNO()
        case "AMEA": MapPaths.AMEA()
        case "AMSW": MapPaths.AMSW()
        case "AMNW": MapPaths.AMNW()
        case "AMIN": MapPaths.AMIN()
        case "AMCE": MapPaths.AMCE()
        case "AMCR": MapPaths.AMCR()
        case "AMWE": MapPaths.AMWE()
        case "AMNE": MapPaths.AMNE()
        case "AMSO": MapPaths.AMSO()
        case "ASNO": MapPaths.ASNO()
        case "ASEA": MapPaths.ASEA()
        case "ASSE": MapPaths.ASSE()
        case "ASHI": MapPaths.ASHI()
        case "ASSO": MapPaths.ASSO()
        case "ASSW": MapPaths.ASSW()
        case "ASWE": MapPaths.ASWE()
        case "ASCE": MapPaths.ASCE()
        case "ASIN": MapPaths.ASIN()
        case "EUEA": MapPaths.EUEA()
        case "EUWE": MapPaths.EUWE()
        case "OCAU": MapPaths.OCAU()
        case "OCMD": MapPaths.OCMD()
        case "OCMR": MapPaths.OCMR()
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
