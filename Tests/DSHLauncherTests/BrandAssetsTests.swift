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

    func testAppIconSourceIsHighResolutionWithTransparentCorners() throws {
        let url = try XCTUnwrap(Bundle.module.url(forResource: "AppIconSource", withExtension: "png"))
        let data = try Data(contentsOf: url)
        let representation = try XCTUnwrap(NSBitmapImageRep(data: data))

        XCTAssertEqual(representation.pixelsWide, 1024)
        XCTAssertEqual(representation.pixelsHigh, 1024)
        XCTAssertTrue(representation.hasAlpha)
        XCTAssertEqual(representation.colorAt(x: 0, y: 0)?.alphaComponent ?? 1, 0, accuracy: 0.01)
        XCTAssertEqual(representation.colorAt(x: 512, y: 512)?.alphaComponent ?? 0, 1, accuracy: 0.01)
    }

    func testApplicationIconLoadsBundledImageForDock() throws {
        let image = try XCTUnwrap(
            ApplicationIcon.load(
                from: Bundle.module,
                resource: "AppIconSource",
                extension: "png"
            )
        )

        XCTAssertGreaterThan(image.size.width, 0)
        XCTAssertGreaterThan(image.size.height, 0)
        XCTAssertFalse(image.isTemplate)
    }

    func testApplicationIconReturnsNilWhenResourceIsMissing() {
        XCTAssertNil(
            ApplicationIcon.load(
                from: Bundle.module,
                resource: "MissingAppIcon",
                extension: "icns"
            )
        )
    }
}
