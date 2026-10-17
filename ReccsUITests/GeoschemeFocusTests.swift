//
//  GeoschemeFocusTests.swift
//  ReccsUITests
//
//  Drives the Siri Remote across the Geoscheme map and checks that every
//  arrow press from every subregion lands somewhere a person would expect.
//

import XCTest

final class GeoschemeFocusTests: XCTestCase {
    let app = XCUIApplication()
    let remote = XCUIRemote.shared

    // Acceptable destinations for each region and direction (first is preferred).
    // "-" = focus stays put, "TAB" = focus moves up to the tab bar.
    let allowed: [String: [String: [String]]] = [
        "AMNO": ["U": ["TAB"], "D": ["AMIN", "AMEA"], "L": ["AMNW", "-"], "R": ["EUWE", "EUEA"]],
        "AMNW": ["U": ["AMNO"], "D": ["AMSW"], "L": ["-", "OCPL"], "R": ["AMIN"]],
        "AMIN": ["U": ["AMNO"], "D": ["AMSW", "AMCE"], "L": ["AMNW"], "R": ["AMEA"]],
        "AMEA": ["U": ["AMNO"], "D": ["AMCR"], "L": ["AMIN"], "R": ["EUWE", "AFNO"]],
        "AMSW": ["U": ["AMNW", "AMIN"], "D": ["AMCE"], "L": ["-", "OCPL"], "R": ["AMIN", "AMEA"]],
        "AMCE": ["U": ["AMSW", "AMIN"], "D": ["AMWE"], "L": ["OCPL", "-"], "R": ["AMCR"]],
        "AMCR": ["U": ["AMEA"], "D": ["AMNE", "AMWE"], "L": ["AMCE"], "R": ["AFWE", "AFNO"]],
        "AMWE": ["U": ["AMCE", "AMCR"], "D": ["AMSO"], "L": ["OCPL"], "R": ["AMNE"]],
        "AMNE": ["U": ["AMCR"], "D": ["AMSO"], "L": ["AMWE"], "R": ["AFWE", "AFCE"]],
        "AMSO": ["U": ["AMWE", "AMNE"], "D": ["-"], "L": ["OCPL", "AMWE", "-"], "R": ["AFSO", "-"]],
        "EUWE": ["U": ["TAB"], "D": ["AFNO"], "L": ["AMNO", "AMEA"], "R": ["EUEA"]],
        "EUEA": ["U": ["TAB"], "D": ["ASWE", "ASSW"], "L": ["EUWE"], "R": ["ASCE", "ASNO"]],
        "AFNO": ["U": ["EUWE"], "D": ["AFWE", "AFNC"], "L": ["AMEA", "AMCR", "-"], "R": ["AFNC", "ASWE", "AFNE"]],
        "AFNC": ["U": ["AFNO"], "D": ["AFCE"], "L": ["AFWE", "AFNO"], "R": ["AFNE"]],
        "AFWE": ["U": ["AFNO"], "D": ["AFCE", "-"], "L": ["AMNE", "AMCR", "-"], "R": ["AFNC", "AFCE"]],
        "AFNE": ["U": ["ASWE", "AFNO"], "D": ["AFEA"], "L": ["AFNC"], "R": ["ASSO", "-"]],
        "AFCE": ["U": ["AFNC"], "D": ["AFSO"], "L": ["AFWE"], "R": ["AFEA"]],
        "AFEA": ["U": ["AFNE"], "D": ["AFSO", "OCMD"], "L": ["AFCE"], "R": ["OCMD", "ASSO", "-"]],
        "AFSO": ["U": ["AFCE", "AFEA"], "D": ["-"], "L": ["AMSO", "-"], "R": ["OCMD"]],
        "OCMD": ["U": ["AFEA"], "D": ["-"], "L": ["AFSO"], "R": ["OCAU", "ASSO", "-"]],
        "ASWE": ["U": ["EUEA"], "D": ["AFNE"], "L": ["AFNO", "AFNC"], "R": ["ASSW"]],
        "ASSW": ["U": ["ASCE", "EUEA"], "D": ["ASSO", "-"], "L": ["ASWE"], "R": ["ASSO", "ASHI"]],
        "ASCE": ["U": ["ASNO"], "D": ["ASSW", "ASHI"], "L": ["EUEA"], "R": ["ASIN"]],
        "ASNO": ["U": ["TAB"], "D": ["ASIN", "ASCE"], "L": ["EUEA", "ASCE"], "R": ["-", "AMNO"]],
        "ASIN": ["U": ["ASNO"], "D": ["ASEA", "ASHI"], "L": ["ASCE"], "R": ["ASEA", "-"]],
        "ASHI": ["U": ["ASIN", "ASCE"], "D": ["ASSO", "ASSE"], "L": ["ASSW", "ASSO"], "R": ["ASEA"]],
        "ASSO": ["U": ["ASHI"], "D": ["-", "OCMR"], "L": ["ASSW", "ASWE"], "R": ["ASSE"]],
        "ASEA": ["U": ["ASIN"], "D": ["ASSE"], "L": ["ASHI"], "R": ["OCMC", "-", "OCPL"]],
        "ASSE": ["U": ["ASEA", "ASHI"], "D": ["OCMR"], "L": ["ASSO"], "R": ["OCMR", "OCMC"]],
        "OCMR": ["U": ["ASSE"], "D": ["OCAU"], "L": ["ASSE", "ASSO", "-"], "R": ["OCML"]],
        "OCMC": ["U": ["ASEA", "-", "TAB"], "D": ["OCML"], "L": ["OCMR", "ASEA"], "R": ["OCPL"]],
        "OCML": ["U": ["OCMC"], "D": ["OCAU"], "L": ["OCMR"], "R": ["OCPL"]],
        "OCAU": ["U": ["OCML", "OCMR"], "D": ["-"], "L": ["OCMD", "OCMR"], "R": ["OCPL", "OCML"]],
        "OCPL": ["U": ["OCMC", "TAB", "-"], "D": ["-", "OCAU"], "L": ["OCML", "OCMC"], "R": ["AMWE"]],    ]

    override func setUpWithError() throws {
        continueAfterFailure = true
    }

    private func focusedRegion() -> String {
        Thread.sleep(forTimeInterval: 0.45)
        let focused = app.descendants(matching: .any)
            .matching(NSPredicate(format: "hasFocus == true"))
            .allElementsBoundByIndex
        for element in focused where element.identifier.hasPrefix("region-") {
            return String(element.identifier.dropFirst("region-".count))
        }
        return "TAB"
    }

    private func press(_ direction: String) {
        switch direction {
        case "U": remote.press(.up)
        case "D": remote.press(.down)
        case "L": remote.press(.left)
        default: remote.press(.right)
        }
    }

    func testEveryArrowPressLandsOnAnExpectedRegion() throws {
        app.launch()
        Thread.sleep(forTimeInterval: 4)
        remote.press(.up)
        Thread.sleep(forTimeInterval: 0.6)
        remote.press(.right)
        Thread.sleep(forTimeInterval: 1.5)
        remote.press(.down)

        var current = focusedRegion()
        XCTAssertNotEqual(current, "TAB", "Pressing down from the Geoscheme tab should focus a region")
        guard current != "TAB" else { return }

        let directions = ["U", "D", "L", "R"]
        var edges: [String: [String: String]] = [:]

        func returnToMap() -> String {
            var region = focusedRegion()
            var attempts = 0
            while region == "TAB" && attempts < 3 {
                remote.press(.down)
                region = focusedRegion()
                attempts += 1
            }
            return region
        }

        // Explore: walk known edges to the nearest region with an untested direction, then press it.
        var rounds = 0
        while true {
            rounds += 1
            guard rounds < 400 else { XCTFail("Exploration did not finish; focus may have left the map"); break }
            var previous: [String: (String, String)] = [:]
            var queue = [current]
            var visited: Set<String> = [current]
            var target: String?
            while !queue.isEmpty {
                let node = queue.removeFirst()
                if directions.contains(where: { edges[node]?[$0] == nil }) { target = node; break }
                for direction in directions {
                    if let next = edges[node]?[direction], next != "TAB", next != "-", !visited.contains(next) {
                        visited.insert(next)
                        previous[next] = (node, direction)
                        queue.append(next)
                    }
                }
            }
            guard let target else { break }

            var path: [String] = []
            var step = target
            while step != current {
                let (parent, direction) = previous[step]!
                path.insert(direction, at: 0)
                step = parent
            }
            var onPath = true
            for direction in path {
                let expected = edges[current]![direction]!
                press(direction)
                let landed = focusedRegion()
                if landed != expected {
                    XCTFail("Non-deterministic focus: \(current) \(direction) went to \(landed), earlier \(expected)")
                    current = landed == "TAB" ? returnToMap() : landed
                    onPath = false
                    break
                }
                current = landed
            }
            if !onPath { continue }

            let direction = directions.first(where: { edges[current]?[$0] == nil })!
            press(direction)
            let landed = focusedRegion()
            edges[current, default: [:]][direction] = landed == current ? "-" : landed
            if landed == "TAB" {
                current = returnToMap()
                if current == "TAB" { XCTFail("Could not return focus to the map"); return }
            } else {
                current = landed
            }
        }

        for (region, moves) in allowed {
            XCTAssertNotNil(edges[region], "\(region) was never reached")
            for (direction, options) in moves {
                guard let landed = edges[region]?[direction] else { continue }
                XCTAssertTrue(options.contains(landed),
                              "\(region) \(direction) went to \(landed); expected one of \(options)")
            }
        }
    }
}
