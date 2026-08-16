import Foundation
import XCTest
@testable import DSHLauncher

final class CommandRunnerTests: XCTestCase {
    func testRunStreamsStandardOutputAndError() async throws {
        let recorder = OutputRecorder()
        let result = try await CommandRunner().run(
            executable: URL(fileURLWithPath: "/bin/sh"),
            arguments: ["-c", "printf stdout; printf stderr >&2"],
            currentDirectory: nil,
            environment: nil,
            onOutput: { recorder.append($0) }
        )

        XCTAssertEqual(result.status, 0)
        XCTAssertTrue(recorder.text.contains("stdout"))
        XCTAssertTrue(recorder.text.contains("stderr"))
    }
}

private final class OutputRecorder: @unchecked Sendable {
    private let lock = NSLock()
    private var output = ""

    var text: String {
        lock.lock()
        defer { lock.unlock() }
        return output
    }

    func append(_ text: String) {
        lock.lock()
        output += text
        lock.unlock()
    }
}
