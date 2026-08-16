import AppKit

@MainActor
final class StatusItemController: NSObject {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private var phase: RuntimePhase = .stopped

    var onToggleWindow: (() -> Void)?
    var onOpen: (() -> Void)?
    var onStop: (() -> Void)?
    var onRestart: (() -> Void)?
    var onUpdate: (() -> Void)?
    var onOpenLog: (() -> Void)?
    var onOpenData: (() -> Void)?
    var onQuit: (() -> Void)?

    override init() {
        super.init()
        guard let button = statusItem.button else { return }
        button.image = brandImage()
        button.target = self
        button.action = #selector(clicked)
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }

    func render(_ phase: RuntimePhase) {
        self.phase = phase
        statusItem.button?.toolTip = statusText
        statusItem.button?.image = brandImage()
    }

    @objc private func clicked() {
        if NSApp.currentEvent?.type == .rightMouseUp {
            guard let button = statusItem.button else { return }
            menu().popUp(positioning: nil, at: NSPoint(x: 0, y: button.bounds.maxY + 4), in: button)
        } else {
            onToggleWindow?()
        }
    }

    private func menu() -> NSMenu {
        let menu = NSMenu()
        let status = NSMenuItem(title: statusText, action: nil, keyEquivalent: "")
        status.isEnabled = false
        menu.addItem(status)
        if case .running(let version, _) = phase {
            let versionItem = NSMenuItem(title: "版本 \(version)", action: nil, keyEquivalent: "")
            versionItem.isEnabled = false
            menu.addItem(versionItem)
        }
        menu.addItem(.separator())
        menu.addItem(item("打开 DSH", action: #selector(open), key: "o", enabled: !phase.isBusy))
        menu.addItem(item("停止服务", action: #selector(stop), enabled: isRunning))
        menu.addItem(item("重新启动服务", action: #selector(restart), enabled: isRunning))
        menu.addItem(item("检查 DSH 更新…", action: #selector(update), enabled: !phase.isBusy))
        menu.addItem(.separator())
        menu.addItem(item("打开日志", action: #selector(openLog)))
        menu.addItem(item("打开数据目录", action: #selector(openData)))
        menu.addItem(.separator())
        menu.addItem(item("退出 DSH Launcher", action: #selector(quit), key: "q"))
        return menu
    }

    private var isRunning: Bool {
        if case .running = phase { return true }
        return false
    }

    private var statusText: String {
        switch phase {
        case .stopped: return "DSH 服务未启动"
        case .checkingVersion: return "正在检查 DSH 更新…"
        case .installing(let version): return "正在安装 DSH \(version)…"
        case .starting(let version): return "正在启动 DSH \(version)…"
        case .running: return "DSH 服务正在运行"
        case .stopping: return "正在停止 DSH 服务…"
        case .failed: return "DSH 服务启动失败"
        }
    }

    private func item(_ title: String, action: Selector, key: String = "", enabled: Bool = true) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
        item.target = self
        item.isEnabled = enabled
        return item
    }

    private func brandImage() -> NSImage? {
        guard let url = brandResourceBundle.url(forResource: "DeepSeekFish", withExtension: "svg"),
              let image = NSImage(contentsOf: url) else { return nil }
        image.size = NSSize(width: 19, height: 19)
        image.isTemplate = true
        image.accessibilityDescription = "DeepSeek Harness"
        return image
    }

    private var brandResourceBundle: Bundle {
        if let resources = Bundle.main.resourceURL,
           let bundle = Bundle(
               url: resources.appendingPathComponent("DSHLauncher_DSHLauncher.bundle", isDirectory: true)
           ) {
            return bundle
        }
        return Bundle.module
    }

    @objc private func open() { onOpen?() }
    @objc private func stop() { onStop?() }
    @objc private func restart() { onRestart?() }
    @objc private func update() { onUpdate?() }
    @objc private func openLog() { onOpenLog?() }
    @objc private func openData() { onOpenData?() }
    @objc private func quit() { onQuit?() }
}
