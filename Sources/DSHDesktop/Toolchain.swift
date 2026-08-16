import Foundation

struct Toolchain: Equatable {
    let node: URL
    let npm: URL

    var binDirectory: URL { node.deletingLastPathComponent() }
}

struct ToolchainLocator {
    private let environment: [String: String]
    private let bundleResources: URL?
    private let fileManager: FileManager

    init(
        environment: [String: String] = ProcessInfo.processInfo.environment,
        bundleResources: URL? = Bundle.main.resourceURL,
        fileManager: FileManager = .default
    ) {
        self.environment = environment
        self.bundleResources = bundleResources
        self.fileManager = fileManager
    }

    func locate() throws -> Toolchain {
        var directories: [URL] = []
        if let bundleResources {
            directories.append(bundleResources.appendingPathComponent("runtime/bin", isDirectory: true))
        }
        directories.append(contentsOf: pathDirectories())
        directories.append(contentsOf: ["/opt/homebrew/bin", "/usr/local/bin", "/opt/local/bin"].map {
            URL(fileURLWithPath: $0, isDirectory: true)
        })

        var visited = Set<String>()
        for directory in directories where visited.insert(directory.path).inserted {
            let node = directory.appendingPathComponent("node")
            let npm = directory.appendingPathComponent("npm")
            guard fileManager.isExecutableFile(atPath: node.path),
                  fileManager.isExecutableFile(atPath: npm.path) else { continue }
            return Toolchain(node: node, npm: npm)
        }
        throw LauncherError.noNodeRuntime
    }

    private func pathDirectories() -> [URL] {
        (environment["PATH"] ?? "")
            .split(separator: ":")
            .map { URL(fileURLWithPath: String($0), isDirectory: true) }
    }
}
