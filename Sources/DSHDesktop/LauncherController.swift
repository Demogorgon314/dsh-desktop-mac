import Foundation

@MainActor
final class LauncherController {
    private(set) var phase: RuntimePhase = .stopped {
        didSet { onPhaseChanged?(phase) }
    }

    var onPhaseChanged: ((RuntimePhase) -> Void)?
    var onNotice: ((String) -> Void)?
    var onInstallOutput: ((String) -> Void)?

    let paths: AppPaths
    private let registry: LatestVersionProviding
    private let commandRunner: CommandRunning
    private var toolchain: Toolchain?
    private var store: VersionStore?
    private var runtime: HarnessRuntime?

    init(
        paths: AppPaths,
        registry: LatestVersionProviding = NPMRegistryClient(),
        commandRunner: CommandRunning = CommandRunner()
    ) {
        self.paths = paths
        self.registry = registry
        self.commandRunner = commandRunner
    }

    func start() async {
        guard !phase.isBusy else { return }
        if case .running = phase { return }

        do {
            try paths.prepare()
            let dependencies = try await prepareDependencies()
            phase = .checkingVersion
            let version = try await preferredVersion(store: dependencies.store)
            try await launch(version: version, dependencies: dependencies)
        } catch {
            phase = .failed(message: userMessage(error))
        }
    }

    func stop() async {
        guard !phase.isBusy else { return }
        guard case .running = phase else {
            phase = .stopped
            return
        }
        phase = .stopping
        await runtime?.stop()
        phase = .stopped
    }

    func restart() async {
        guard !phase.isBusy else { return }
        let currentVersion: String?
        if case .running(let version, _) = phase { currentVersion = version } else { currentVersion = store?.current()?.version }
        phase = .stopping
        await runtime?.stop()
        guard let version = currentVersion,
              let toolchain,
              let store else {
            phase = .stopped
            await start()
            return
        }
        do {
            try await launch(
                version: version,
                dependencies: (toolchain, store)
            )
        } catch {
            phase = .failed(message: userMessage(error))
        }
    }

    func update() async {
        guard !phase.isBusy else { return }
        let phaseBeforeUpdate = phase
        var stoppedForUpdate = false
        do {
            try paths.prepare()
            let dependencies = try await prepareDependencies()
            let runningVersion: String?
            if case .running(let version, _) = phaseBeforeUpdate { runningVersion = version } else { runningVersion = nil }
            phase = .checkingVersion
            let latest = try await registry.latestVersion()
            if latest == runningVersion || (runningVersion == nil && latest == dependencies.store.current()?.version) {
                if case .running(let runningVersion, let url) = phaseBeforeUpdate {
                    phase = .running(version: runningVersion, url: url)
                } else {
                    phase = .stopped
                }
                onNotice?("当前已经是最新 DSH 版本 \(latest)。")
                return
            }

            await runtime?.stop()
            stoppedForUpdate = true
            try await launch(version: latest, dependencies: dependencies)
            onNotice?("DSH 已更新到 \(latest)。")
        } catch {
            if !stoppedForUpdate, case .running = phaseBeforeUpdate {
                phase = phaseBeforeUpdate
                onNotice?("检查 DSH 更新失败：\(userMessage(error))")
            } else {
                phase = .failed(message: userMessage(error))
            }
        }
    }

    func shutdown() async {
        phase = .stopping
        await runtime?.stop()
        phase = .stopped
    }

    nonisolated static func shouldStartOffline(version: String, installedVersion: String?) -> Bool {
        installedVersion == version
    }

    private func prepareDependencies() async throws -> (toolchain: Toolchain, store: VersionStore) {
        if let toolchain, let store { return (toolchain, store) }
        let toolchain = try ToolchainLocator().locate()
        try await validate(toolchain: toolchain)
        let store = VersionStore(paths: paths)
        self.toolchain = toolchain
        self.store = store
        return (toolchain, store)
    }

    private func validate(toolchain: Toolchain) async throws {
        let result = try await commandRunner.run(
            executable: toolchain.node,
            arguments: ["--version"],
            currentDirectory: nil,
            environment: nil
        )
        guard result.status == 0 else {
            throw LauncherError.commandFailed(command: "node --version", code: result.status, output: result.output)
        }
        let version = result.output.trimmingCharacters(in: .whitespacesAndNewlines)
        let components = version.drop(while: { !$0.isNumber }).split(separator: ".")
        let major = components.first.flatMap { Int($0) } ?? 0
        let minor = components.dropFirst().first.flatMap { Int($0) } ?? 0
        guard major >= 24 || (major == 22 && minor >= 19) else {
            throw LauncherError.unsupportedNodeVersion(version)
        }
    }

    private func preferredVersion(store: VersionStore) async throws -> String {
        do {
            return try await registry.latestVersion()
        } catch {
            if let current = store.current() { return current.version }
            throw LauncherError.noInstalledRuntime
        }
    }

    private func launch(
        version: String,
        dependencies: (toolchain: Toolchain, store: VersionStore)
    ) async throws {
        phase = .installing(version: version)
        let runtime = HarnessRuntime(paths: paths, toolchain: dependencies.toolchain)
        runtime.onOutput = { [weak self] output in self?.onInstallOutput?(output) }
        runtime.onUnexpectedExit = { [weak self] code in
            self?.phase = .failed(message: userMessage(LauncherError.harnessExited(code)))
        }
        self.runtime = runtime

        let previous = dependencies.store.current()
        if Self.shouldStartOffline(version: version, installedVersion: previous?.version) {
            do {
                let url = try await runtime.start(version: version, offline: true)
                phase = .running(version: version, url: url)
                return
            } catch {
                onNotice?("本地 npm 缓存不可用，正在重新下载 DSH \(version)。")
            }
        }

        do {
            let url = try await runtime.start(version: version, offline: false)
            try dependencies.store.markCurrent(version: version)
            phase = .running(version: version, url: url)
        } catch {
            if let previous, previous.version != version {
                onNotice?("在线启动 DSH \(version) 失败，正在从 npm 缓存启动 \(previous.version)。")
                let fallbackURL = try await runtime.start(version: previous.version, offline: true)
                phase = .running(version: previous.version, url: fallbackURL)
                return
            }
            throw error
        }
    }
}

private func userMessage(_ error: Error) -> String {
    (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
}
