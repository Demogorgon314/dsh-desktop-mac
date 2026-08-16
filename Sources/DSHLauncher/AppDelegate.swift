import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var launcher: LauncherController?
    private let windowController = MainWindowController()
    private let statusController = StatusItemController()
    private var terminationReplyPending = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        do {
            let launcher = LauncherController(paths: try AppPaths())
            self.launcher = launcher
            bind(launcher)
            windowController.render(.checkingVersion)
            windowController.showAndFocus()
            Task { await launcher.start() }
        } catch {
            windowController.render(.failed(message: error.localizedDescription))
            windowController.showAndFocus()
        }
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        guard !terminationReplyPending, let launcher else { return .terminateNow }
        terminationReplyPending = true
        Task {
            await launcher.shutdown()
            sender.reply(toApplicationShouldTerminate: true)
        }
        return .terminateLater
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        windowController.showAndFocus()
        return true
    }

    private func bind(_ launcher: LauncherController) {
        launcher.onPhaseChanged = { [weak self] phase in
            self?.windowController.render(phase)
            self?.statusController.render(phase)
        }
        launcher.onNotice = { [weak self] message in self?.showNotice(message) }
        windowController.onRetry = { Task { await launcher.start() } }
        statusController.onToggleWindow = { [weak self] in
            guard let self else { return }
            self.windowController.toggle()
            if case .stopped = launcher.phase { Task { await launcher.start() } }
        }
        statusController.onOpen = { [weak self] in
            self?.windowController.showAndFocus()
            if case .stopped = launcher.phase { Task { await launcher.start() } }
        }
        statusController.onStop = { Task { await launcher.stop() } }
        statusController.onRestart = { Task { await launcher.restart() } }
        statusController.onUpdate = { Task { await launcher.update() } }
        statusController.onOpenLog = { NSWorkspace.shared.activateFileViewerSelecting([launcher.paths.harnessLog]) }
        statusController.onOpenData = { NSWorkspace.shared.open(launcher.paths.root) }
        statusController.onQuit = { NSApp.terminate(nil) }
    }

    private func showNotice(_ message: String) {
        let alert = NSAlert()
        alert.messageText = "DSH Launcher"
        alert.informativeText = message
        alert.alertStyle = .informational
        alert.addButton(withTitle: "好")
        if let window = windowController.window, window.isVisible {
            alert.beginSheetModal(for: window)
        } else {
            alert.runModal()
        }
    }
}
