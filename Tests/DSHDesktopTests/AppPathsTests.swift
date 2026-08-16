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

    func testUserDataIsSeparateFromVersionedRuntime() throws {
        let root = URL(fileURLWithPath: "/tmp/dsh-launcher-tests", isDirectory: true)
        let dshHome = URL(fileURLWithPath: "/tmp/existing-dsh-home", isDirectory: true)
        let paths = try AppPaths(root: root, dshHome: dshHome)

        XCTAssertEqual(paths.dshHome.path, "/tmp/existing-dsh-home")
        XCTAssertEqual(paths.runtime(version: "1.2.3").path, "/tmp/dsh-launcher-tests/runtime/versions/1.2.3")
        XCTAssertFalse(paths.dshHome.path.hasPrefix(paths.runtimes.path))
    }

    func testPrepareCreatesPersistentPluginAndRuntimeDirectories() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let paths = try AppPaths(root: root, dshHome: root.appendingPathComponent("dsh-home"))

        try paths.prepare()

        for directory in [paths.dshHome, paths.runtimes, paths.npmCache, paths.launchRoot, paths.logs] {
            var isDirectory: ObjCBool = false
            XCTAssertTrue(FileManager.default.fileExists(atPath: directory.path, isDirectory: &isDirectory))
            XCTAssertTrue(isDirectory.boolValue)
        }
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
