import Foundation
import XCTest
@testable import DSHLauncher

final class AppPathsTests: XCTestCase {
    func testUserDataIsSeparateFromVersionedRuntime() throws {
        let root = URL(fileURLWithPath: "/tmp/dsh-launcher-tests", isDirectory: true)
        let paths = try AppPaths(root: root)

        XCTAssertEqual(paths.dshHome.path, "/tmp/dsh-launcher-tests/harness")
        XCTAssertEqual(paths.runtime(version: "1.2.3").path, "/tmp/dsh-launcher-tests/runtime/versions/1.2.3")
        XCTAssertFalse(paths.dshHome.path.hasPrefix(paths.runtimes.path))
    }

    func testPrepareCreatesPersistentPluginAndRuntimeDirectories() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let paths = try AppPaths(root: root)

        try paths.prepare()

        for directory in [paths.dshHome, paths.runtimes, paths.npmCache, paths.launchRoot, paths.logs] {
            var isDirectory: ObjCBool = false
            XCTAssertTrue(FileManager.default.fileExists(atPath: directory.path, isDirectory: &isDirectory))
            XCTAssertTrue(isDirectory.boolValue)
        }
    }
}
