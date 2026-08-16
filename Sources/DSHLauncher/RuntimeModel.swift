import Foundation

enum RuntimePhase: Equatable {
    case stopped
    case checkingVersion
    case installing(version: String)
    case starting(version: String)
    case running(version: String, url: URL)
    case stopping
    case failed(message: String)

    var isBusy: Bool {
        switch self {
        case .checkingVersion, .installing, .starting, .stopping:
            return true
        case .stopped, .running, .failed:
            return false
        }
    }
}

struct InstalledRuntime: Codable, Equatable {
    let version: String
}

enum LauncherError: LocalizedError {
    case noNodeRuntime
    case unsupportedNodeVersion(String)
    case noInstalledRuntime
    case invalidRegistryResponse
    case commandFailed(command: String, code: Int32, output: String)
    case harnessExited(Int32)
    case startupTimedOut

    var errorDescription: String? {
        switch self {
        case .noNodeRuntime:
            return "没有找到 Node.js。请安装 Node.js 22.19 或 24 及以上版本。"
        case .unsupportedNodeVersion(let version):
            return "Node.js \(version) 不受支持，需要 22.19.x 或 24 及以上版本。"
        case .noInstalledRuntime:
            return "无法连接 npm，并且本机还没有可用的 DSH 版本。"
        case .invalidRegistryResponse:
            return "npm registry 返回了无法识别的 DSH 版本信息。"
        case .commandFailed(let command, let code, let output):
            let detail = output.trimmingCharacters(in: .whitespacesAndNewlines)
            return detail.isEmpty
                ? "\(command) 执行失败，退出码 \(code)。"
                : "\(command) 执行失败，退出码 \(code)：\n\(detail)"
        case .harnessExited(let code):
            return "DSH 服务意外退出，退出码 \(code)。"
        case .startupTimedOut:
            return "DSH 服务没有在 45 秒内完成启动。"
        }
    }
}
