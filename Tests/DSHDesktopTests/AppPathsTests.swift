import Foundation
import XCTest
@testable import DSHDesktop

final class AppPathsTests: XCTestCase {
    func testApplicationSupportDirectoryMatchesProductName() {
        XCTAssertEqual(AppPaths.applicationSupportDirectoryName, "DSH Desktop")
    }

    func testDefaultDshHomeMatchesCommandLineDefault() throws {
        let launcherRoot = URL(fileURLWithPath: "/tmp/dsh-launcher-tests", isDirectory: true)
        let paths = try AppPaths(root: launcherRoot, environment: [:])

        XCTAssertEqual(
            paths.dshHome,
            FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".dsh", isDirectory: true)
        )
    }

    func testUserDataIsSeparateFromLauncherState() throws {
        let root = URL(fileURLWithPath: "/tmp/dsh-launcher-tests", isDirectory: true)
        let dshHome = URL(fileURLWithPath: "/tmp/existing-dsh-home", isDirectory: true)
        let paths = try AppPaths(root: root, dshHome: dshHome)

        XCTAssertEqual(paths.dshHome.path, "/tmp/existing-dsh-home")
        XCTAssertEqual(paths.currentRuntime.path, "/tmp/dsh-launcher-tests/current.json")
        XCTAssertFalse(paths.dshHome.path.hasPrefix(paths.root.path))
    }

    func testPrepareCreatesOnlyLauncherStateAndPluginDirectories() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let paths = try AppPaths(root: root, dshHome: root.appendingPathComponent("dsh-home"))

        try paths.prepare()

        for directory in [paths.root, paths.dshHome, paths.launchRoot, paths.logs] {
            var isDirectory: ObjCBool = false
            XCTAssertTrue(FileManager.default.fileExists(atPath: directory.path, isDirectory: &isDirectory))
            XCTAssertTrue(isDirectory.boolValue)
        }
        XCTAssertFalse(FileManager.default.fileExists(atPath: root.appendingPathComponent("runtime").path))
    }

    func testEnvironmentDshHomeOverridesCommandLineDefault() throws {
        let paths = try AppPaths(
            root: URL(fileURLWithPath: "/tmp/launcher"),
            environment: ["DSH_HOME": "~/custom-dsh"],
            homeDirectory: URL(fileURLWithPath: "/Users/example", isDirectory: true)
        )

        XCTAssertEqual(paths.dshHome.path, "/Users/example/custom-dsh")
    }
}
