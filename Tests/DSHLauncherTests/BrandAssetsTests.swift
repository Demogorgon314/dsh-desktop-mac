import AppKit
import XCTest
@testable import DSHLauncher

final class BrandAssetsTests: XCTestCase {
    func testUpstreamDeepSeekFishLoadsAsMenuBarImage() throws {
        let url = try XCTUnwrap(Bundle.module.url(forResource: "DeepSeekFish", withExtension: "svg"))
        let image = try XCTUnwrap(NSImage(contentsOf: url))

        XCTAssertGreaterThan(image.size.width, 0)
        XCTAssertGreaterThan(image.size.height, 0)
    }

    func testAppIconUsesBlackDeepSeekFishOnWhite() throws {
        let url = try XCTUnwrap(Bundle.module.url(forResource: "AppIconSource", withExtension: "svg"))
        let source = try String(contentsOf: url, encoding: .utf8)

        XCTAssertTrue(source.contains("fill=\"#fff\""))
        XCTAssertTrue(source.contains("DeepSeekFish.svg"))
        XCTAssertTrue(source.contains("x=\"100\" y=\"100\" width=\"824\" height=\"824\""))
        XCTAssertTrue(source.contains("x=\"200\" y=\"200\" width=\"624\" height=\"624\""))
        XCTAssertFalse(source.contains("#4D6BFE"))
    }
}
