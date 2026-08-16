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

enum StatusTone: Equatable {
    case working
    case idle
    case error
}

struct StatusPresentation: Equatable {
    let title: String
    let detail: String
    let tone: StatusTone
    let actionTitle: String?
    let showsInstallLog: Bool

    var showsActivity: Bool { tone == .working }

    init?(phase: RuntimePhase) {
        switch phase {
        case .running:
            return nil
        case .checkingVersion:
            title = "正在检查更新"
            detail = "正在获取 DeepSeek Harness 的最新版本。"
            tone = .working
            actionTitle = nil
            showsInstallLog = false
        case .installing(let version):
            title = "正在安装 DSH"
            detail = "正在准备 \(version)，首次安装可能需要几分钟。"
            tone = .working
            actionTitle = nil
            showsInstallLog = true
        case .starting(let version):
            title = "正在启动 DSH"
            detail = "版本 \(version) 即将就绪。"
            tone = .working
            actionTitle = nil
            showsInstallLog = false
        case .stopping:
            title = "正在停止服务"
            detail = "正在安全关闭当前 DSH 进程。"
            tone = .working
            actionTitle = nil
            showsInstallLog = false
        case .stopped:
            title = "DSH 服务已停止"
            detail = "启动本地服务后即可继续使用。"
            tone = .idle
            actionTitle = "启动服务"
            showsInstallLog = false
        case .failed(let message):
            title = "无法启动 DSH"
            detail = message
            tone = .error
            actionTitle = "重试"
            showsInstallLog = false
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
