import XCTest
@testable import DSHDesktop

final class NPMExecTests: XCTestCase {
    func testOnlineArgumentsUseExactDshAndPnpmVersions() {
        let arguments = HarnessRuntime.npmArguments(
            version: "0.1.0-rc.6",
            offline: false,
            port: 8_765
        )

        XCTAssertEqual(arguments, [
            "exec",
            "--yes",
            "--prefer-online",
            "--package=@deepseek-ai/dsh@0.1.0-rc.6",
            "--package=pnpm@\(HarnessRuntime.pnpmVersion)",
            "--",
            "dsh",
            "web",
            "--host", "127.0.0.1",
            "--port", "8765",
        ])
    }

    func testOfflineArgumentsRequireNpmCache() {
        let arguments = HarnessRuntime.npmArguments(
            version: "1.2.3",
            offline: true,
            port: 9_000
        )

        XCTAssertTrue(arguments.contains("--offline"))
        XCTAssertFalse(arguments.contains("--prefer-online"))
        XCTAssertTrue(arguments.contains("--package=@deepseek-ai/dsh@1.2.3"))
        XCTAssertTrue(arguments.contains("--package=pnpm@\(HarnessRuntime.pnpmVersion)"))
    }
}
