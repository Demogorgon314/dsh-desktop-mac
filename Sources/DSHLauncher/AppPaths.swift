import Foundation

struct AppPaths {
    let root: URL

    init(root: URL? = nil, fileManager: FileManager = .default) throws {
        if let root {
            self.root = root
        } else {
            let applicationSupport = try fileManager.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            self.root = applicationSupport.appendingPathComponent("DSH Launcher", isDirectory: true)
        }
    }

    var runtimes: URL { root.appendingPathComponent("runtime/versions", isDirectory: true) }
    var staging: URL { root.appendingPathComponent("runtime/staging", isDirectory: true) }
    var currentRuntime: URL { root.appendingPathComponent("runtime/current.json") }
    var npmCache: URL { root.appendingPathComponent("runtime/npm-cache", isDirectory: true) }
    var dshHome: URL { root.appendingPathComponent("harness", isDirectory: true) }
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
}
