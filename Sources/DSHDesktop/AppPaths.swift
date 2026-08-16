import Foundation

struct AppPaths {
    static let applicationSupportDirectoryName = "DSH Desktop"

    let root: URL
    let dshHome: URL

    init(
        root: URL? = nil,
        dshHome: URL? = nil,
        environment: [String: String] = ProcessInfo.processInfo.environment,
        homeDirectory: URL = FileManager.default.homeDirectoryForCurrentUser,
        fileManager: FileManager = .default
    ) throws {
        if let root {
            self.root = root
        } else {
            let applicationSupport = try fileManager.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            self.root = applicationSupport.appendingPathComponent(
                Self.applicationSupportDirectoryName,
                isDirectory: true
            )
        }
        self.dshHome = dshHome ?? Self.resolveDshHome(
            environment: environment,
            homeDirectory: homeDirectory
        )
    }

    var runtimes: URL { root.appendingPathComponent("runtime/versions", isDirectory: true) }
    var staging: URL { root.appendingPathComponent("runtime/staging", isDirectory: true) }
    var currentRuntime: URL { root.appendingPathComponent("runtime/current.json") }
    var npmCache: URL { root.appendingPathComponent("runtime/npm-cache", isDirectory: true) }
    var launchRoot: URL { root.appendingPathComponent("launch-root", isDirectory: true) }
    var logs: URL { root.appendingPathComponent("logs", isDirectory: true) }
    var harnessLog: URL { logs.appendingPathComponent("dsh.log") }

    func runtime(version: String) -> URL {
        runtimes.appendingPathComponent(version, isDirectory: true)
    }

    func prepare(fileManager: FileManager = .default) throws {
        for directory in [runtimes, staging, npmCache, dshHome, launchRoot, logs] {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        }
    }

    private static func resolveDshHome(
        environment: [String: String],
        homeDirectory: URL
    ) -> URL {
        guard let configured = environment["DSH_HOME"]?.trimmingCharacters(in: .whitespacesAndNewlines),
              !configured.isEmpty else {
            return homeDirectory.appendingPathComponent(".dsh", isDirectory: true)
        }
        if configured == "~" { return homeDirectory }
        if configured.hasPrefix("~/") {
            return homeDirectory.appendingPathComponent(String(configured.dropFirst(2)), isDirectory: true)
        }
        return URL(fileURLWithPath: configured, isDirectory: true).standardizedFileURL
    }
}
