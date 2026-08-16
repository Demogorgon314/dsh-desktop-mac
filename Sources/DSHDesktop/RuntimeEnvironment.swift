import Foundation

enum RuntimeEnvironment {
    static func make(
        paths: AppPaths,
        toolchain: Toolchain,
        parent: [String: String] = ProcessInfo.processInfo.environment
    ) -> [String: String] {
        var environment = parent
        let fallbackPath = "/usr/bin:/bin:/usr/sbin:/sbin"
        let inheritedPath = parent["PATH"].flatMap { $0.isEmpty ? nil : $0 } ?? fallbackPath

        environment["DSH_HOME"] = paths.dshHome.path
        environment["NO_COLOR"] = "1"
        environment["npm_config_color"] = "false"
        environment["PATH"] = [toolchain.binDirectory.path, inheritedPath]
            .joined(separator: ":")
        return environment
    }
}
