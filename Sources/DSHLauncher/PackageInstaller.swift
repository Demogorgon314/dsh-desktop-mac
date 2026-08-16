import Foundation

final class PackageInstaller {
    static let pnpmVersion = "11.7.0"

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

    func installIfNeeded(version: String) async throws -> URL {
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
        let result = try await commandRunner.run(
            executable: toolchain.npm,
            arguments: [
                "install",
                "--no-audit",
                "--no-fund",
                "--save-exact",
                "@deepseek-ai/dsh@\(version)",
                "pnpm@\(Self.pnpmVersion)",
            ],
            currentDirectory: staging,
            environment: environment
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
