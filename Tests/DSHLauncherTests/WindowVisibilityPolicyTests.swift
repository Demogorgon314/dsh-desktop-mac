import AppKit
import XCTest
@testable import DSHLauncher

final class WindowVisibilityPolicyTests: XCTestCase {
    func testVisibleWindowUsesDockApplicationPolicy() {
        XCTAssertEqual(WindowVisibilityPolicy.activationPolicy(isVisible: true), .regular)
    }

    func testHiddenWindowUsesMenuBarOnlyPolicy() {
        XCTAssertEqual(WindowVisibilityPolicy.activationPolicy(isVisible: false), .accessory)
    }
}
