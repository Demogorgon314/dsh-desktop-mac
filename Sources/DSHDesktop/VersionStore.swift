import Foundation

final class VersionStore {
    private let paths: AppPaths
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    init(paths: AppPaths) {
        self.paths = paths
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    }

    func current() -> InstalledRuntime? {
        guard let data = try? Data(contentsOf: paths.currentRuntime),
              let runtime = try? decoder.decode(InstalledRuntime.self, from: data) else { return nil }
        return runtime
    }

    func markCurrent(version: String) throws {
        let data = try encoder.encode(InstalledRuntime(version: version))
        try data.write(to: paths.currentRuntime, options: .atomic)
    }

}
