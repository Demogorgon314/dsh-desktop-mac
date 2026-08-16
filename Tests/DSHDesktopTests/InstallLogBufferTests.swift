import XCTest
@testable import DSHDesktop

final class InstallLogBufferTests: XCTestCase {
    func testAppendRemovesTerminalFormattingAndCarriageReturns() {
        var buffer = InstallLogBuffer()

        buffer.append("\u{001B}[32mnpm info\u{001B}[0m\rfetch package")

        XCTAssertEqual(buffer.text, "npm info\nfetch package")
    }

    func testAppendKeepsOnlyTheNewestCharacters() {
        var buffer = InstallLogBuffer()

        buffer.append(String(repeating: "a", count: InstallLogBuffer.characterLimit))
        buffer.append("new")

        XCTAssertEqual(buffer.text.count, InstallLogBuffer.characterLimit)
        XCTAssertTrue(buffer.text.hasSuffix("new"))
    }

    func testResetClearsOutput() {
        var buffer = InstallLogBuffer()
        buffer.append("npm info")

        buffer.reset()

        XCTAssertTrue(buffer.text.isEmpty)
    }
}
