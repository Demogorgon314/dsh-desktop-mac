import Darwin
import Foundation

@MainActor
final class HarnessRuntime {
    private let paths: AppPaths
    private let toolchain: Toolchain
    private let session: URLSession
    private var process: Process?
    private var processGroupWasCreated = false
    private var expectedStop = false
    private var logHandle: FileHandle?

    var onUnexpectedExit: ((Int32) -> Void)?

    init(paths: AppPaths, toolchain: Toolchain, session: URLSession = .shared) {
        self.paths = paths
        self.toolchain = toolchain
        self.session = session
    }

    func start(version: String) async throws -> URL {
        await stop()
        let runtimeDirectory = paths.runtime(version: version)
        let dshEntry = runtimeDirectory.appendingPathComponent("node_modules/@deepseek-ai/dsh/lib/bin.js")
        let port = try LoopbackPort.reserve()
        guard let url = URL(string: "http://127.0.0.1:\(port)") else {
            throw LauncherError.invalidRegistryResponse
        }

        try openLog()
        writeLog("\n[launcher] starting DSH \(version) at \(url.absoluteString)")

        let child = Process()
        let pipe = Pipe()
        child.executableURL = toolchain.node
        child.arguments = [
            "--expose-internals",
            dshEntry.path,
            "web",
            "--host", "127.0.0.1",
            "--port", String(port),
        ]
        child.currentDirectoryURL = paths.launchRoot
        child.environment = RuntimeEnvironment.make(
            paths: paths,
            toolchain: toolchain,
            runtimeDirectory: runtimeDirectory
        )
        child.standardInput = FileHandle.nullDevice
        child.standardOutput = pipe
        child.standardError = pipe

        pipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty else { return }
            Task { @MainActor in self?.writeLog(String(decoding: data, as: UTF8.self)) }
        }
        expectedStop = false
        child.terminationHandler = { [weak self, weak child] terminated in
            pipe.fileHandleForReading.readabilityHandler = nil
            Task { @MainActor in
                guard let self, self.process === child else { return }
                self.process = nil
                self.processGroupWasCreated = false
                self.writeLog("[launcher] DSH exited with status \(terminated.terminationStatus)")
                self.closeLog()
                if !self.expectedStop { self.onUnexpectedExit?(terminated.terminationStatus) }
            }
        }

        do {
            try child.run()
        } catch {
            pipe.fileHandleForReading.readabilityHandler = nil
            closeLog()
            throw error
        }
        process = child
        processGroupWasCreated = setpgid(child.processIdentifier, child.processIdentifier) == 0

        do {
            try await waitUntilReady(url: url, process: child)
            writeLog("[launcher] DSH is ready")
            return url
        } catch {
            await stop()
            throw error
        }
    }

    func stop() async {
        guard let process else {
            closeLog()
            return
        }
        expectedStop = true
        writeLog("[launcher] stopping DSH")
        signal(process: process, signal: SIGTERM)

        for _ in 0..<40 where process.isRunning {
            try? await Task.sleep(nanoseconds: 100_000_000)
        }
        if process.isRunning {
            writeLog("[launcher] forcing DSH to stop")
            signal(process: process, signal: SIGKILL)
        }
        for _ in 0..<10 where process.isRunning {
            try? await Task.sleep(nanoseconds: 100_000_000)
        }
        self.process = nil
        processGroupWasCreated = false
        closeLog()
    }

    private func waitUntilReady(url: URL, process: Process) async throws {
        for _ in 0..<180 {
            guard process.isRunning else { throw LauncherError.harnessExited(process.terminationStatus) }
            var request = URLRequest(url: url)
            request.timeoutInterval = 1
            request.cachePolicy = .reloadIgnoringLocalCacheData
            if let (_, response) = try? await session.data(for: request),
               let http = response as? HTTPURLResponse,
               (200..<500).contains(http.statusCode) {
                return
            }
            try await Task.sleep(nanoseconds: 250_000_000)
        }
        throw LauncherError.startupTimedOut
    }

    private func signal(process: Process, signal: Int32) {
        if processGroupWasCreated {
            kill(-process.processIdentifier, signal)
        } else {
            kill(process.processIdentifier, signal)
        }
    }

    private func openLog() throws {
        if !FileManager.default.fileExists(atPath: paths.harnessLog.path) {
            FileManager.default.createFile(atPath: paths.harnessLog.path, contents: nil)
        }
        let handle = try FileHandle(forWritingTo: paths.harnessLog)
        try handle.seekToEnd()
        logHandle = handle
    }

    private func writeLog(_ text: String) {
        let normalized = text.hasSuffix("\n") ? text : text + "\n"
        try? logHandle?.write(contentsOf: Data(normalized.utf8))
    }

    private func closeLog() {
        try? logHandle?.close()
        logHandle = nil
    }
}

enum LoopbackPort {
    static func reserve() throws -> UInt16 {
        let descriptor = socket(AF_INET, SOCK_STREAM, 0)
        guard descriptor >= 0 else { throw POSIXError(.init(rawValue: errno) ?? .EIO) }
        defer { close(descriptor) }

        var address = sockaddr_in()
        address.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        address.sin_family = sa_family_t(AF_INET)
        address.sin_port = 0
        address.sin_addr = in_addr(s_addr: inet_addr("127.0.0.1"))

        let bindResult = withUnsafePointer(to: &address) { pointer in
            pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                Darwin.bind(descriptor, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
            }
        }
        guard bindResult == 0 else { throw POSIXError(.init(rawValue: errno) ?? .EIO) }

        var length = socklen_t(MemoryLayout<sockaddr_in>.size)
        let nameResult = withUnsafeMutablePointer(to: &address) { pointer in
            pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                getsockname(descriptor, $0, &length)
            }
        }
        guard nameResult == 0 else { throw POSIXError(.init(rawValue: errno) ?? .EIO) }
        return UInt16(bigEndian: address.sin_port)
    }
}
