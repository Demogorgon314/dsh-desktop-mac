import Foundation
import XCTest
@testable import DSHLauncher

final class RuntimeEnvironmentTests: XCTestCase {
    func testEnvironmentKeepsPluginsInStableHomeAndMakesPnpmDiscoverable() throws {
        let root = URL(fileURLWithPath: "/tmp/dsh-launcher", isDirectory: true)
        let paths = try AppPaths(root: root, dshHome: root.appendingPathComponent("harness"))
        let toolchain = Toolchain(
            node: URL(fileURLWithPath: "/runtime/bin/node"),
            npm: URL(fileURLWithPath: "/runtime/bin/npm")
        )
        let runtime = paths.runtime(version: "0.1.0")

        let environment = RuntimeEnvironment.make(
            paths: paths,
            toolchain: toolchain,
            runtimeDirectory: runtime,
            parent: ["PATH": "/usr/bin:/bin", "CUSTOM": "preserved"]
        )

        XCTAssertEqual(environment["DSH_HOME"], "/tmp/dsh-launcher/harness")
        XCTAssertEqual(environment["CUSTOM"], "preserved")
        XCTAssertEqual(
            environment["PATH"],
            "/tmp/dsh-launcher/runtime/versions/0.1.0/node_modules/.bin:/runtime/bin:/usr/bin:/bin"
        )
        XCTAssertFalse(environment["DSH_HOME"]!.contains("/runtime/versions/"))
    }
}
