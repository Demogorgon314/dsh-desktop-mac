import AppKit

enum ApplicationIcon {
    static func load(
        from bundle: Bundle,
        resource: String = "AppIcon",
        extension fileExtension: String = "icns"
    ) -> NSImage? {
        guard let url = bundle.url(forResource: resource, withExtension: fileExtension),
              let image = NSImage(contentsOf: url) else { return nil }
        image.isTemplate = false
        return image
    }

    @MainActor
    static func install(on application: NSApplication, from bundle: Bundle = .main) {
        guard let image = load(from: bundle) else { return }
        application.applicationIconImage = image
        application.dockTile.display()
    }
}
