import Foundation

struct InstallLogBuffer {
    static let characterLimit = 32_000

    private(set) var text = ""

    mutating func reset() {
        text = ""
    }

    mutating func append(_ output: String) {
        text += Self.sanitize(output)
        if text.count > Self.characterLimit {
            text = String(text.suffix(Self.characterLimit))
        }
    }

    static func sanitize(_ output: String) -> String {
        let withoutANSI = output.replacingOccurrences(
            of: "\u{001B}\\[[0-?]*[ -/]*[@-~]",
            with: "",
            options: .regularExpression
        )
        return withoutANSI.replacingOccurrences(of: "\r", with: "\n")
    }
}
