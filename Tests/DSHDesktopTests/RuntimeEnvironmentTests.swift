import Foundation
import XCTest
@testable import DSHDesktop

final class RuntimeEnvironmentTests: XCTestCase {
    func testEnvironmentKeepsPluginsInStableHomeAndMakesPnpmDiscoverable() throws {
        let root = URL(fileURLWithPath: "/tmp/dsh-launcher", isDirectory: true)
        let paths = try AppPaths(root: root, dshHome: root.appendingPathComponent("harness"))
        let toolchain = Toolchain(
            node: URL(fileURLWithPath: "/runtime/bin/node"),
            npm: URL(fileURLWithPath: "/runtime/bin/npm")
        )
        let environment = RuntimeEnvironment.make(
            paths: paths,
            toolchain: toolchain,
            parent: ["PATH": "/usr/bin:/bin", "CUSTOM": "preserved"]
        )

        XCTAssertEqual(environment["DSH_HOME"], "/tmp/dsh-launcher/harness")
        XCTAssertEqual(environment["CUSTOM"], "preserved")
        XCTAssertEqual(
            environment["PATH"],
            "/runtime/bin:/usr/bin:/bin"
        )
        XCTAssertEqual(environment["npm_config_color"], "false")
        XCTAssertNil(environment["npm_config_cache"])
    }
}
