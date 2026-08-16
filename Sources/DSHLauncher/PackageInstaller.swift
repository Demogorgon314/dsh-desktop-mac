import Foundation

final class PackageInstaller {
    static let pnpmVersion = "11.7.0"

    static func installArguments(version: String) -> [String] {
        [
            "install",
            "--no-audit",
            "--no-fund",
            "--loglevel=info",
            "--save-exact",
            "@deepseek-ai/dsh@\(version)",
            "pnpm@\(pnpmVersion)",
        ]
    }

    static func commandDescription(version: String) -> String {
        "$ npm \(installArguments(version: version).joined(separator: " "))"
    }

    private let paths: AppPaths
    private let toolchain: Toolchain
    private let store: VersionStore
    private let commandRunner: CommandRunning
    private let fileManager: FileManager

    init(
        paths: AppPaths,
        toolchain: Toolchain,
        store: VersionStore,
        commandRunner: CommandRunning = CommandRunner(),
        fileManager: FileManager = .default
    ) {
        self.paths = paths
        self.toolchain = toolchain
        self.store = store
        self.commandRunner = commandRunner
        self.fileManager = fileManager
    }

    func installIfNeeded(
        version: String,
        onOutput: (@Sendable (String) -> Void)? = nil
    ) async throws -> URL {
        if store.isUsable(version: version) { return paths.runtime(version: version) }

        let staging = paths.staging.appendingPathComponent("\(version)-\(UUID().uuidString)", isDirectory: true)
        try fileManager.createDirectory(at: staging, withIntermediateDirectories: true)
        defer { try? fileManager.removeItem(at: staging) }

        let manifest = """
        {
          "name": "dsh-launcher-runtime",
          "private": true,
          "version": "1.0.0"
        }
        """
        try Data(manifest.utf8).write(to: staging.appendingPathComponent("package.json"), options: .atomic)

        var environment = ProcessInfo.processInfo.environment
        environment["PATH"] = [toolchain.binDirectory.path, environment["PATH"] ?? "/usr/bin:/bin"]
            .joined(separator: ":")
        environment["npm_config_cache"] = paths.npmCache.path
        environment["npm_config_color"] = "false"
        environment["NO_COLOR"] = "1"
        let result = try await commandRunner.run(
            executable: toolchain.npm,
            arguments: Self.installArguments(version: version),
            currentDirectory: staging,
            environment: environment,
            onOutput: onOutput
        )
        guard result.status == 0 else {
            throw LauncherError.commandFailed(command: "npm install", code: result.status, output: result.output)
        }

        let destination = paths.runtime(version: version)
        if fileManager.fileExists(atPath: destination.path) {
            try fileManager.removeItem(at: destination)
        }
        try fileManager.moveItem(at: staging, to: destination)
        guard store.isUsable(version: version) else {
            throw LauncherError.commandFailed(
                command: "npm install",
                code: -1,
                output: "安装结果缺少 DSH 或 pnpm 可执行文件。"
            )
        }
        return destination
    }
}
