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

    func testAppIconUsesDeepSeekBrandBlue() throws {
        let url = try XCTUnwrap(Bundle.module.url(forResource: "AppIconSource", withExtension: "svg"))
        let source = try String(contentsOf: url, encoding: .utf8)

        XCTAssertTrue(source.contains("#4D6BFE"))
        XCTAssertTrue(source.contains("DeepSeekFish.svg"))
    }
}
