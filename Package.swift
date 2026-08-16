// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "DSHLauncher",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "DSHLauncher", targets: ["DSHLauncher"]),
    ],
    targets: [
        .executableTarget(
            name: "DSHLauncher",
            path: "Sources/DSHLauncher"
        ),
        .testTarget(
            name: "DSHLauncherTests",
            dependencies: ["DSHLauncher"],
            path: "Tests/DSHLauncherTests"
        ),
    ],
    swiftLanguageModes: [.v5]
)
