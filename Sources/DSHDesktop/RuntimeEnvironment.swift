import Foundation

enum RuntimeEnvironment {
    static func make(
        paths: AppPaths,
        toolchain: Toolchain,
        runtimeDirectory: URL,
        parent: [String: String] = ProcessInfo.processInfo.environment
    ) -> [String: String] {
        var environment = parent
        let packageBin = runtimeDirectory.appendingPathComponent("node_modules/.bin", isDirectory: true)
        let fallbackPath = "/usr/bin:/bin:/usr/sbin:/sbin"
        let inheritedPath = parent["PATH"].flatMap { $0.isEmpty ? nil : $0 } ?? fallbackPath

        environment["DSH_HOME"] = paths.dshHome.path
        environment["NO_COLOR"] = "1"
        environment["npm_config_cache"] = paths.npmCache.path
        environment["PATH"] = [packageBin.path, toolchain.binDirectory.path, inheritedPath]
            .joined(separator: ":")
        return environment
    }
}
