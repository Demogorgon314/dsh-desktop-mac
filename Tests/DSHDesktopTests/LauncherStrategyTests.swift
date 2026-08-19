import XCTest
@testable import DSHDesktop

final class LauncherStrategyTests: XCTestCase {
    func testCurrentVersionStartsFromCompletedCache() {
        XCTAssertTrue(
            LauncherController.shouldStartOffline(
                version: "1.2.3",
                installedVersion: "1.2.3"
            )
        )
    }

    func testNewOrMissingVersionUsesOnlineInstall() {
        XCTAssertFalse(
            LauncherController.shouldStartOffline(
                version: "1.2.4",
                installedVersion: "1.2.3"
            )
        )
        XCTAssertFalse(
            LauncherController.shouldStartOffline(
                version: "1.2.4",
                installedVersion: nil
            )
        )
    }
}
