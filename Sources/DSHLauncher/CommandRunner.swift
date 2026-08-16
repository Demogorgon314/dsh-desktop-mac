import Foundation

struct CommandResult: Equatable {
    let status: Int32
    let output: String
}

protocol CommandRunning {
    func run(
        executable: URL,
        arguments: [String],
        currentDirectory: URL?,
        environment: [String: String]?
    ) async throws -> CommandResult
}

final class CommandRunner: CommandRunning {
    func run(
        executable: URL,
        arguments: [String],
        currentDirectory: URL? = nil,
        environment: [String: String]? = nil
    ) async throws -> CommandResult {
        try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            let outputPipe = Pipe()
            let output = LockedOutput()

            process.executableURL = executable
            process.arguments = arguments
            process.currentDirectoryURL = currentDirectory
            if let environment { process.environment = environment }
            process.standardOutput = outputPipe
            process.standardError = outputPipe

            outputPipe.fileHandleForReading.readabilityHandler = { handle in
                let data = handle.availableData
                guard !data.isEmpty else { return }
                output.append(data)
            }
            process.terminationHandler = { process in
                outputPipe.fileHandleForReading.readabilityHandler = nil
                let tail = outputPipe.fileHandleForReading.readDataToEndOfFile()
                output.append(tail)
                let result = CommandResult(
                    status: process.terminationStatus,
                    output: output.string()
                )
                continuation.resume(returning: result)
            }

            do {
                try process.run()
            } catch {
                outputPipe.fileHandleForReading.readabilityHandler = nil
                continuation.resume(throwing: error)
            }
        }
    }
}

private final class LockedOutput: @unchecked Sendable {
    private let lock = NSLock()
    private var data = Data()

    func append(_ newData: Data) {
        lock.lock()
        data.append(newData)
        lock.unlock()
    }

    func string() -> String {
        lock.lock()
        defer { lock.unlock() }
        return String(decoding: data, as: UTF8.self)
    }
}
