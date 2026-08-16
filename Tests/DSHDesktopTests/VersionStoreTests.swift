import Foundation
import XCTest
@testable import DSHDesktop

final class VersionStoreTests: XCTestCase {
    func testCurrentReturnsLastSuccessfullyStartedVersion() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let paths = try AppPaths(root: root, dshHome: root.appendingPathComponent("dsh-home"))
        try paths.prepare()
        let store = VersionStore(paths: paths)

        XCTAssertNil(store.current())
        try store.markCurrent(version: "1.0.0")
        XCTAssertEqual(store.current(), InstalledRuntime(version: "1.0.0"))
    }

    func testMarkCurrentDoesNotMoveOrRewritePluginHome() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let paths = try AppPaths(root: root, dshHome: root.appendingPathComponent("dsh-home"))
        try paths.prepare()
        let plugin = paths.dshHome.appendingPathComponent("profiles/web/package.json")
        try FileManager.default.createDirectory(at: plugin.deletingLastPathComponent(), withIntermediateDirectories: true)
        let pluginData = Data("{\"dependencies\":{\"example-plugin\":\"1.0.0\"}}".utf8)
        try pluginData.write(to: plugin)

        try VersionStore(paths: paths).markCurrent(version: "2.0.0")

        XCTAssertEqual(try Data(contentsOf: plugin), pluginData)
    }
}
