import AppKit
import WebKit

@MainActor
final class MainWindowController: NSWindowController, NSWindowDelegate, WKNavigationDelegate, WKUIDelegate {
    private let webView: WKWebView
    private let statusView = NSVisualEffectView()
    private let statusPanel = NSVisualEffectView()
    private let brandBadge = NSView()
    private let brandImageView = NSImageView()
    private let productLabel = NSTextField(labelWithString: "DSH Desktop")
    private let productDetailLabel = NSTextField(labelWithString: "DeepSeek Harness")
    private let statusIndicator = NSView()
    private let statusTitleLabel = NSTextField(labelWithString: "正在准备 DSH")
    private let statusDetailLabel = NSTextField(labelWithString: "正在初始化本地服务。")
    private let activityIndicator = NSProgressIndicator()
    private let installLogLabel = NSTextField(labelWithString: "安装日志")
    private let installLogScrollView = NSScrollView()
    private let installLogTextView = NSTextView(frame: .zero)
    private let retryButton = NSButton(title: "重试", target: nil, action: nil)
    private var installLogBuffer = InstallLogBuffer()
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
        window.title = "DSH Desktop"
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
        if case .running(_, let url) = phase {
            showHarness(url: url)
        } else if let presentation = StatusPresentation(phase: phase) {
            showStatus(presentation)
        }
    }

    func appendInstallOutput(_ output: String) {
        installLogBuffer.append(output)
        installLogTextView.string = installLogBuffer.text
        installLogTextView.scrollToEndOfDocument(nil)
    }

    func showAndFocus() {
        guard let window else { return }
        NSApp.setActivationPolicy(WindowVisibilityPolicy.activationPolicy(isVisible: true))
        NSApp.activate(ignoringOtherApps: true)
        showWindow(nil)
        if window.isMiniaturized { window.deminiaturize(nil) }
        window.makeKeyAndOrderFront(nil)
    }

    func toggle() {
        guard let window else { return }
        if window.isVisible && window.isKeyWindow {
            hide()
        } else {
            showAndFocus()
        }
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        hide()
        return false
    }

    func hide() {
        window?.orderOut(nil)
        NSApp.setActivationPolicy(WindowVisibilityPolicy.activationPolicy(isVisible: false))
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
        statusView.material = .underWindowBackground
        statusView.state = .active
        statusView.blendingMode = .withinWindow

        statusPanel.translatesAutoresizingMaskIntoConstraints = false
        statusPanel.material = .contentBackground
        statusPanel.state = .active
        statusPanel.blendingMode = .withinWindow
        statusPanel.wantsLayer = true
        statusPanel.layer?.cornerRadius = 22
        statusPanel.layer?.masksToBounds = true
        statusPanel.layer?.borderWidth = 0.5
        statusPanel.layer?.borderColor = NSColor.separatorColor.withAlphaComponent(0.35).cgColor

        brandBadge.translatesAutoresizingMaskIntoConstraints = false
        brandBadge.wantsLayer = true
        brandBadge.layer?.cornerRadius = 17
        brandBadge.layer?.backgroundColor = NSColor.controlAccentColor.withAlphaComponent(0.10).cgColor
        brandBadge.layer?.borderWidth = 0.5
        brandBadge.layer?.borderColor = NSColor.controlAccentColor.withAlphaComponent(0.18).cgColor

        brandImageView.translatesAutoresizingMaskIntoConstraints = false
        brandImageView.image = brandImage()
        brandImageView.imageScaling = .scaleProportionallyDown
        brandImageView.contentTintColor = .labelColor
        brandImageView.setAccessibilityLabel("DeepSeek")

        productLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        productLabel.textColor = .labelColor
        productDetailLabel.font = .systemFont(ofSize: 12, weight: .regular)
        productDetailLabel.textColor = .secondaryLabelColor

        statusIndicator.translatesAutoresizingMaskIntoConstraints = false
        statusIndicator.wantsLayer = true
        statusIndicator.layer?.cornerRadius = 4

        statusTitleLabel.font = .systemFont(ofSize: 24, weight: .semibold)
        statusTitleLabel.textColor = .labelColor
        statusTitleLabel.maximumNumberOfLines = 2
        statusDetailLabel.font = .systemFont(ofSize: 14, weight: .regular)
        statusDetailLabel.textColor = .secondaryLabelColor
        statusDetailLabel.maximumNumberOfLines = 0
        statusDetailLabel.lineBreakMode = .byWordWrapping

        activityIndicator.style = .bar
        activityIndicator.controlSize = .small
        activityIndicator.isIndeterminate = true
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false

        installLogLabel.font = .systemFont(ofSize: 11, weight: .medium)
        installLogLabel.textColor = .secondaryLabelColor
        installLogLabel.isHidden = true

        installLogTextView.isEditable = false
        installLogTextView.isSelectable = true
        installLogTextView.isRichText = false
        installLogTextView.drawsBackground = false
        installLogTextView.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
        installLogTextView.textColor = .secondaryLabelColor
        installLogTextView.textContainerInset = NSSize(width: 12, height: 10)
        installLogTextView.frame = NSRect(x: 0, y: 0, width: 484, height: 132)
        installLogTextView.minSize = NSSize(width: 0, height: 132)
        installLogTextView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        installLogTextView.isVerticallyResizable = true
        installLogTextView.isHorizontallyResizable = false
        installLogTextView.autoresizingMask = [.width]
        installLogTextView.textContainer?.widthTracksTextView = true

        installLogScrollView.documentView = installLogTextView
        installLogScrollView.translatesAutoresizingMaskIntoConstraints = false
        installLogScrollView.hasVerticalScroller = true
        installLogScrollView.autohidesScrollers = true
        installLogScrollView.borderType = .noBorder
        installLogScrollView.drawsBackground = false
        installLogScrollView.wantsLayer = true
        installLogScrollView.layer?.cornerRadius = 10
        installLogScrollView.layer?.backgroundColor = NSColor.textBackgroundColor.withAlphaComponent(0.55).cgColor
        installLogScrollView.isHidden = true

        retryButton.target = self
        retryButton.action = #selector(retry)
        retryButton.bezelStyle = .rounded
        retryButton.controlSize = .large
        retryButton.keyEquivalent = "\r"
        retryButton.translatesAutoresizingMaskIntoConstraints = false
        retryButton.isHidden = true

        let productText = NSStackView(views: [productLabel, productDetailLabel])
        productText.orientation = .vertical
        productText.alignment = .leading
        productText.spacing = 2

        let brandRow = NSStackView(views: [brandBadge, productText])
        brandRow.orientation = .horizontal
        brandRow.alignment = .centerY
        brandRow.spacing = 14

        let titleRow = NSStackView(views: [statusIndicator, statusTitleLabel])
        titleRow.orientation = .horizontal
        titleRow.alignment = .centerY
        titleRow.spacing = 12

        let statusContent = NSStackView(views: [
            brandRow,
            titleRow,
            statusDetailLabel,
            activityIndicator,
            installLogLabel,
            installLogScrollView,
            retryButton,
        ])
        statusContent.translatesAutoresizingMaskIntoConstraints = false
        statusContent.orientation = .vertical
        statusContent.alignment = .leading
        statusContent.spacing = 10
        statusContent.setCustomSpacing(30, after: brandRow)
        statusContent.setCustomSpacing(8, after: titleRow)
        statusContent.setCustomSpacing(24, after: statusDetailLabel)
        statusContent.setCustomSpacing(18, after: activityIndicator)
        statusContent.setCustomSpacing(7, after: installLogLabel)

        content.addSubview(webView)
        content.addSubview(statusView)
        statusView.addSubview(statusPanel)
        statusPanel.addSubview(statusContent)
        brandBadge.addSubview(brandImageView)
        NSLayoutConstraint.activate([
            webView.leadingAnchor.constraint(equalTo: content.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: content.trailingAnchor),
            webView.topAnchor.constraint(equalTo: content.topAnchor),
            webView.bottomAnchor.constraint(equalTo: content.bottomAnchor),
            statusView.leadingAnchor.constraint(equalTo: content.leadingAnchor),
            statusView.trailingAnchor.constraint(equalTo: content.trailingAnchor),
            statusView.topAnchor.constraint(equalTo: content.topAnchor),
            statusView.bottomAnchor.constraint(equalTo: content.bottomAnchor),
            statusPanel.centerXAnchor.constraint(equalTo: statusView.centerXAnchor),
            statusPanel.centerYAnchor.constraint(equalTo: statusView.centerYAnchor, constant: -24),
            statusPanel.widthAnchor.constraint(equalToConstant: 560),
            statusContent.leadingAnchor.constraint(equalTo: statusPanel.leadingAnchor, constant: 38),
            statusContent.trailingAnchor.constraint(equalTo: statusPanel.trailingAnchor, constant: -38),
            statusContent.topAnchor.constraint(equalTo: statusPanel.topAnchor, constant: 34),
            statusContent.bottomAnchor.constraint(equalTo: statusPanel.bottomAnchor, constant: -38),
            brandBadge.widthAnchor.constraint(equalToConstant: 58),
            brandBadge.heightAnchor.constraint(equalToConstant: 58),
            brandImageView.centerXAnchor.constraint(equalTo: brandBadge.centerXAnchor),
            brandImageView.centerYAnchor.constraint(equalTo: brandBadge.centerYAnchor),
            brandImageView.widthAnchor.constraint(equalToConstant: 38),
            brandImageView.heightAnchor.constraint(equalToConstant: 38),
            statusIndicator.widthAnchor.constraint(equalToConstant: 8),
            statusIndicator.heightAnchor.constraint(equalToConstant: 8),
            activityIndicator.widthAnchor.constraint(equalTo: statusContent.widthAnchor),
            activityIndicator.heightAnchor.constraint(equalToConstant: 4),
            installLogScrollView.widthAnchor.constraint(equalTo: statusContent.widthAnchor),
            installLogScrollView.heightAnchor.constraint(equalToConstant: 132),
        ])
    }

    private func showHarness(url: URL) {
        allowedOrigin = url
        activityIndicator.stopAnimation(nil)
        statusView.isHidden = true
        webView.isHidden = false
        if webView.url?.scheme != url.scheme || webView.url?.host != url.host || webView.url?.port != url.port {
            webView.load(URLRequest(url: url))
        }
    }

    private func showStatus(_ presentation: StatusPresentation) {
        statusTitleLabel.stringValue = presentation.title
        statusDetailLabel.stringValue = presentation.detail
        statusIndicator.layer?.backgroundColor = statusColor(for: presentation.tone).cgColor
        activityIndicator.isHidden = !presentation.showsActivity
        if presentation.showsActivity {
            activityIndicator.startAnimation(nil)
        } else {
            activityIndicator.stopAnimation(nil)
        }
        if presentation.showsInstallLog && installLogScrollView.isHidden {
            installLogBuffer.reset()
            installLogTextView.string = ""
        }
        installLogLabel.isHidden = !presentation.showsInstallLog
        installLogScrollView.isHidden = !presentation.showsInstallLog
        retryButton.isHidden = presentation.actionTitle == nil
        if let actionTitle = presentation.actionTitle {
            retryButton.title = actionTitle
        }
        statusView.isHidden = false
        webView.isHidden = true
    }

    private func statusColor(for tone: StatusTone) -> NSColor {
        switch tone {
        case .working: return .controlAccentColor
        case .idle: return .secondaryLabelColor
        case .error: return .systemRed
        }
    }

    private func brandImage() -> NSImage? {
        guard let url = Bundle.module.url(forResource: "DeepSeekFish", withExtension: "svg"),
              let image = NSImage(contentsOf: url) else { return nil }
        image.isTemplate = true
        return image
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

enum WindowVisibilityPolicy {
    static func activationPolicy(isVisible: Bool) -> NSApplication.ActivationPolicy {
        isVisible ? .regular : .accessory
    }
}
