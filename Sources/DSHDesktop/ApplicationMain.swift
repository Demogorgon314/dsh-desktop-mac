import AppKit

@main
enum ApplicationMain {
    @MainActor
    static func main() {
        let application = NSApplication.shared
        let delegate = AppDelegate()
        ApplicationIcon.install(on: application)
        ApplicationMenu.install(on: application)
        application.delegate = delegate
        application.run()
    }
}
