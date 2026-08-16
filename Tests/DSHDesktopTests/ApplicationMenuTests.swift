import AppKit
import XCTest
@testable import DSHDesktop

final class ApplicationMenuTests: XCTestCase {
    @MainActor
    func testEditMenuRoutesStandardClipboardShortcutsThroughResponderChain() throws {
        let mainMenu = ApplicationMenu.make()
        let editMenu = try XCTUnwrap(mainMenu.item(withTitle: "Edit")?.submenu)

        let expectedItems: [(title: String, action: Selector, key: String)] = [
            ("Cut", #selector(NSText.cut(_:)), "x"),
            ("Copy", #selector(NSText.copy(_:)), "c"),
            ("Paste", #selector(NSText.paste(_:)), "v"),
            ("Select All", #selector(NSText.selectAll(_:)), "a"),
        ]

        for expected in expectedItems {
            let item = try XCTUnwrap(editMenu.item(withTitle: expected.title))
            XCTAssertEqual(item.action, expected.action)
            XCTAssertEqual(item.keyEquivalent, expected.key)
            XCTAssertEqual(item.keyEquivalentModifierMask, .command)
            XCTAssertNil(item.target)
        }
    }
}
