//
//  RegionOrderTests.swift
//  ReccsUITests
//
//  Opens a region whose newest film isn't a CFF and checks the order its films appear in.
//

import XCTest

final class RegionOrderTests: XCTestCase {
    let app = XCUIApplication()
    let remote = XCUIRemote.shared

    private func focusedRegion() -> String? {
        Thread.sleep(forTimeInterval: 0.45)
        return app.descendants(matching: .any)
            .matching(NSPredicate(format: "hasFocus == true"))
            .allElementsBoundByIndex
            .first { $0.identifier.hasPrefix("region-") }?
            .identifier.replacingOccurrences(of: "region-", with: "")
    }

    func testRegionPageListsFilmTypesInOrder() throws {
        app.launch()
        Thread.sleep(forTimeInterval: 4)
        remote.press(.up)
        Thread.sleep(forTimeInterval: 0.6)
        remote.press(.right)
        Thread.sleep(forTimeInterval: 1.5)
        remote.press(.down)

        // South America sits at the bottom of the map's western side.
        for _ in 0..<8 where focusedRegion() != "AMSO" { remote.press(.left) }
        for _ in 0..<8 where focusedRegion() != "AMSO" { remote.press(.down) }
        for _ in 0..<4 where focusedRegion() != "OCMD" { remote.press(.right) }
        XCTAssertEqual(focusedRegion(), "OCMD")

        remote.press(.select)
        Thread.sleep(forTimeInterval: 3)
        let cards = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH 'region-card-'"))
            .allElementsBoundByIndex
            .sorted { ($0.frame.minY, $0.frame.minX) < ($1.frame.minY, $1.frame.minX) }
            .map { $0.identifier.replacingOccurrences(of: "region-card-", with: "") }
        print("ORDER", cards)
        XCTAssertEqual(cards, ["OCMDCFF", "OCMDGFF"])
    }
}
