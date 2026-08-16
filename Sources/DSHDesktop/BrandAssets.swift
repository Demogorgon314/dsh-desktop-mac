import AppKit

enum BrandAssets {
    private static let bundleName = "DSHDesktop_DSHDesktop.bundle"

    static func image() -> NSImage? {
        image(searchDirectories: defaultSearchDirectories)
    }

    static func image(searchDirectories: [URL]) -> NSImage? {
        for directory in searchDirectories {
            let bundleURL = directory.appendingPathComponent(bundleName, isDirectory: true)
            guard let bundle = Bundle(url: bundleURL),
                  let imageURL = bundle.url(forResource: "DeepSeekFish", withExtension: "svg"),
                  let image = NSImage(contentsOf: imageURL) else { continue }
            return image
        }
        return nil
    }

    private static var defaultSearchDirectories: [URL] {
        [Bundle.main.resourceURL, Bundle.main.bundleURL].compactMap { $0 }
    }
}
