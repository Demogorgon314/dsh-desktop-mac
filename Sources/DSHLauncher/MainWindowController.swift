import AppKit
import WebKit

@MainActor
final class MainWindowController: NSWindowController, NSWindowDelegate, WKNavigationDelegate, WKUIDelegate {
    private let webView: WKWebView
    private let statusView = NSVisualEffectView()
    private let statusLabel = NSTextField(labelWithString: "正在准备 DeepSeek Harness…")
    private let retryButton = NSButton(title: "重试", target: nil, action: nil)
    private var allowedOrigin: URL?
    var onRetry: (() -> Void)?

    init() {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .default()
        webView = WKWebView(frame: .zero, configuration: configuration)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1280, height: 820),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = "DSH Launcher"
        window.minSize = NSSize(width: 900, height: 640)
        window.center()
        window.isReleasedWhenClosed = false
        super.init(window: window)

        window.delegate = self
        webView.navigationDelegate = self
        webView.uiDelegate = self
        configureContent(in: window)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func render(_ phase: RuntimePhase) {
        switch phase {
        case .running(_, let url):
            showHarness(url: url)
        case .failed(let message):
            showStatus(message, retry: true)
        case .stopped:
            showStatus("DSH 服务已停止。", retry: true)
        case .checkingVersion:
            showStatus("正在检查 DSH 版本…")
        case .installing(let version):
            showStatus("正在安装 DSH \(version)…\n首次安装可能需要几分钟。")
        case .starting(let version):
            showStatus("正在启动 DSH \(version)…")
        case .stopping:
            showStatus("正在停止 DSH 服务…")
        }
    }

    func showAndFocus() {
        guard let window else { return }
        NSApp.activate(ignoringOtherApps: true)
        showWindow(nil)
        if window.isMiniaturized { window.deminiaturize(nil) }
        window.makeKeyAndOrderFront(nil)
    }

    func toggle() {
        guard let window else { return }
        if window.isVisible && window.isKeyWindow {
            window.orderOut(nil)
        } else {
            showAndFocus()
        }
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        sender.orderOut(nil)
        return false
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.cancel)
            return
        }
        if isAllowed(url) {
            decisionHandler(.allow)
        } else {
            if ["http", "https"].contains(url.scheme?.lowercased() ?? "") {
                NSWorkspace.shared.open(url)
            }
            decisionHandler(.cancel)
        }
    }

    func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        if let url = navigationAction.request.url, !isAllowed(url) {
            NSWorkspace.shared.open(url)
        } else if let request = navigationAction.request as URLRequest? {
            webView.load(request)
        }
        return nil
    }

    private func configureContent(in window: NSWindow) {
        guard let content = window.contentView else { return }
        webView.translatesAutoresizingMaskIntoConstraints = false
        statusView.translatesAutoresizingMaskIntoConstraints = false
        statusView.material = .sidebar
        statusView.state = .active

        statusLabel.alignment = .center
        statusLabel.font = .systemFont(ofSize: 15)
        statusLabel.maximumNumberOfLines = 0
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        retryButton.target = self
        retryButton.action = #selector(retry)
        retryButton.bezelStyle = .rounded
        retryButton.translatesAutoresizingMaskIntoConstraints = false
        retryButton.isHidden = true

        content.addSubview(webView)
        content.addSubview(statusView)
        statusView.addSubview(statusLabel)
        statusView.addSubview(retryButton)
        NSLayoutConstraint.activate([
            webView.leadingAnchor.constraint(equalTo: content.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: content.trailingAnchor),
            webView.topAnchor.constraint(equalTo: content.topAnchor),
            webView.bottomAnchor.constraint(equalTo: content.bottomAnchor),
            statusView.leadingAnchor.constraint(equalTo: content.leadingAnchor),
            statusView.trailingAnchor.constraint(equalTo: content.trailingAnchor),
            statusView.topAnchor.constraint(equalTo: content.topAnchor),
            statusView.bottomAnchor.constraint(equalTo: content.bottomAnchor),
            statusLabel.centerXAnchor.constraint(equalTo: statusView.centerXAnchor),
            statusLabel.centerYAnchor.constraint(equalTo: statusView.centerYAnchor, constant: -18),
            statusLabel.leadingAnchor.constraint(greaterThanOrEqualTo: statusView.leadingAnchor, constant: 40),
            statusLabel.trailingAnchor.constraint(lessThanOrEqualTo: statusView.trailingAnchor, constant: -40),
            retryButton.centerXAnchor.constraint(equalTo: statusView.centerXAnchor),
            retryButton.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 18),
        ])
    }

    private func showHarness(url: URL) {
        allowedOrigin = url
        statusView.isHidden = true
        webView.isHidden = false
        if webView.url?.scheme != url.scheme || webView.url?.host != url.host || webView.url?.port != url.port {
            webView.load(URLRequest(url: url))
        }
    }

    private func showStatus(_ message: String, retry: Bool = false) {
        statusLabel.stringValue = message
        retryButton.isHidden = !retry
        statusView.isHidden = false
        webView.isHidden = true
    }

    private func isAllowed(_ url: URL) -> Bool {
        guard let allowedOrigin else { return false }
        return url.scheme == allowedOrigin.scheme
            && url.host == allowedOrigin.host
            && url.port == allowedOrigin.port
    }

    @objc private func retry() {
        onRetry?()
    }
}
