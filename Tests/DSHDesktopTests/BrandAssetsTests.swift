import AppKit
import XCTest
@testable import DSHDesktop

final class BrandAssetsTests: XCTestCase {
    func testUpstreamDeepSeekFishLoadsAsMenuBarImage() throws {
        let url = try XCTUnwrap(Bundle.module.url(forResource: "DeepSeekFish", withExtension: "svg"))
        let image = try XCTUnwrap(NSImage(contentsOf: url))

        XCTAssertGreaterThan(image.size.width, 0)
        XCTAssertGreaterThan(image.size.height, 0)
    }

    func testBrandImageLoadsFromPackagedResourceBundleDirectory() throws {
        let image = try XCTUnwrap(
            BrandAssets.image(
                searchDirectories: [Bundle.module.bundleURL.deletingLastPathComponent()]
            )
        )

        XCTAssertGreaterThan(image.size.width, 0)
        XCTAssertGreaterThan(image.size.height, 0)
    }

    func testBrandImageGracefullyHandlesMissingResourceBundle() {
        XCTAssertNil(BrandAssets.image(searchDirectories: [repositoryRoot]))
    }

    func testAppIconSourceIsHighResolutionWithTransparentCorners() throws {
        let data = try Data(contentsOf: appIconSourceURL)
        let representation = try XCTUnwrap(NSBitmapImageRep(data: data))

        XCTAssertEqual(representation.pixelsWide, 1024)
        XCTAssertEqual(representation.pixelsHigh, 1024)
        XCTAssertTrue(representation.hasAlpha)
        XCTAssertEqual(representation.colorAt(x: 0, y: 0)?.alphaComponent ?? 1, 0, accuracy: 0.01)
        XCTAssertEqual(representation.colorAt(x: 512, y: 512)?.alphaComponent ?? 0, 1, accuracy: 0.01)
    }

    func testAppIconSourceIsNotBundledAtRuntime() {
        XCTAssertNil(Bundle.module.url(forResource: "AppIconSource", withExtension: "png"))
    }

    func testPackagedAppIconIsCappedAt512Pixels() throws {
        let image = try XCTUnwrap(NSImage(contentsOf: appIconURL))
        let pixelWidths = image.representations.map(\.pixelsWide)

        XCTAssertEqual(pixelWidths.max(), 512)
        XCTAssertTrue(pixelWidths.contains(512))
    }

    func testApplicationIconLoadsBundledImageForDock() throws {
        let image = try XCTUnwrap(
            ApplicationIcon.load(
                from: Bundle.module,
                resource: "DeepSeekFish",
                extension: "svg"
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

    private var appIconSourceURL: URL {
        repositoryRoot
            .appendingPathComponent("Sources/DSHDesktop/Resources/AppIconSource.png")
    }

    private var appIconURL: URL {
        repositoryRoot.appendingPathComponent("Resources/AppIcon.icns")
    }

    private var repositoryRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }
}
