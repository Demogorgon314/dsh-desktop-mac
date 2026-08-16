import Foundation

final class VersionStore {
    private let paths: AppPaths
    private let fileManager: FileManager
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    init(paths: AppPaths, fileManager: FileManager = .default) {
        self.paths = paths
        self.fileManager = fileManager
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    }

    func current() -> InstalledRuntime? {
        guard let data = try? Data(contentsOf: paths.currentRuntime),
              let runtime = try? decoder.decode(InstalledRuntime.self, from: data),
              isUsable(version: runtime.version) else { return nil }
        return runtime
    }

    func markCurrent(version: String) throws {
        let data = try encoder.encode(InstalledRuntime(version: version))
        try data.write(to: paths.currentRuntime, options: .atomic)
    }

    func isUsable(version: String) -> Bool {
        let directory = paths.runtime(version: version)
        let dsh = directory.appendingPathComponent("node_modules/@deepseek-ai/dsh/lib/bin.js")
        let pnpm = directory.appendingPathComponent("node_modules/.bin/pnpm")
        return fileManager.isReadableFile(atPath: dsh.path)
            && fileManager.isExecutableFile(atPath: pnpm.path)
    }

    func newestUsableVersion() -> String? {
        guard let entries = try? fileManager.contentsOfDirectory(
            at: paths.runtimes,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else { return nil }
        return entries
            .filter { isUsable(version: $0.lastPathComponent) }
            .sorted {
                let lhs = (try? $0.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
                let rhs = (try? $1.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
                return lhs > rhs
            }
            .first?
            .lastPathComponent
    }
}
