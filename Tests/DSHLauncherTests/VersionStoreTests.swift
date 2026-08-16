import Foundation
import XCTest
@testable import DSHLauncher

final class VersionStoreTests: XCTestCase {
    func testRuntimeRequiresBothDshAndPnpm() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let paths = try AppPaths(root: root, dshHome: root.appendingPathComponent("dsh-home"))
        try paths.prepare()
        let store = VersionStore(paths: paths)
        let runtime = paths.runtime(version: "1.0.0")
        let dsh = runtime.appendingPathComponent("node_modules/@deepseek-ai/dsh/lib/bin.js")
        let pnpm = runtime.appendingPathComponent("node_modules/.bin/pnpm")
        try FileManager.default.createDirectory(at: dsh.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data().write(to: dsh)

        XCTAssertFalse(store.isUsable(version: "1.0.0"))

        try FileManager.default.createDirectory(at: pnpm.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data("#!/bin/sh\n".utf8).write(to: pnpm)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: pnpm.path)

        XCTAssertTrue(store.isUsable(version: "1.0.0"))
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
