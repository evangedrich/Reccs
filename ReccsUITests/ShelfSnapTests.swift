//
//  ShelfSnapTests.swift
//  ReccsUITests
//
//  Moves quickly along the home page rows and checks that the focused
//  card always comes to rest in a row's first position.
//

import XCTest

final class ShelfSnapTests: XCTestCase {
    let app = XCUIApplication()
    let remote = XCUIRemote.shared

    /// Where a row's first card rests, measured on launch.
    var firstPositionX: CGFloat = 0

    override func setUpWithError() throws {
        continueAfterFailure = true
    }

    private func focusedCard() -> XCUIElement? {
        app.descendants(matching: .any)
            .matching(NSPredicate(format: "hasFocus == true"))
            .allElementsBoundByIndex
            .first { $0.identifier.hasPrefix("shelf-card-") }
    }

    private func checkSnapped(_ label: String) {
        Thread.sleep(forTimeInterval: 0.5)
        guard let card = focusedCard() else {
            XCTFail("\(label): no card focused")
            return
        }
        let offset = card.frame.minX - firstPositionX
        print("SNAP \(label) \(card.identifier) offset \(Int(offset))")
        XCTAssertEqual(offset, 0, accuracy: 4, "\(label): \(card.identifier) came to rest \(Int(offset)) pt out of position")
    }

    func testFocusedCardSnapsAfterFastMovement() throws {
        app.launch()
        Thread.sleep(forTimeInterval: 5)
        remote.press(.down)
        Thread.sleep(forTimeInterval: 1)
        guard let first = focusedCard() else {
            XCTFail("Pressing down from the tab bar should focus the first row")
            return
        }
        firstPositionX = first.frame.minX

        for round in 1...8 {
            for count in [2, 3, 5] {
                for _ in 0..<count { remote.press(.right) }
                checkSnapped("round \(round): \(count) quick rights")
            }
            remote.press(.right, forDuration: 1.2)
            checkSnapped("round \(round): held right")

            for count in [2, 3] {
                for _ in 0..<count { remote.press(.left) }
                checkSnapped("round \(round): \(count) quick lefts")
            }
            remote.press(.left, forDuration: 2)
            checkSnapped("round \(round): held left")
        }
    }
}
