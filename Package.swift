// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "DSHDesktop",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "DSHDesktop", targets: ["DSHDesktop"]),
    ],
    targets: [
        .executableTarget(
            name: "DSHDesktop",
            path: "Sources/DSHDesktop",
            exclude: ["Resources/AppIconSource.png"],
            resources: [.process("Resources/DeepSeekFish.svg")]
        ),
        .testTarget(
            name: "DSHDesktopTests",
            dependencies: ["DSHDesktop"],
            path: "Tests/DSHDesktopTests"
        ),
    ],
    swiftLanguageModes: [.v5]
)
