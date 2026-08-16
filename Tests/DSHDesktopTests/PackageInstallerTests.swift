import Foundation
import XCTest
@testable import DSHDesktop

final class PackageInstallerTests: XCTestCase {
    func testCommandDescriptionMatchesInstallArguments() {
        let arguments = PackageInstaller.installArguments(version: "0.1.0-rc.6")

        XCTAssertEqual(
            PackageInstaller.commandDescription(version: "0.1.0-rc.6"),
            "$ npm \(arguments.joined(separator: " "))"
        )
    }

    func testInstallIncludesDshAndPnpmWithoutWritingPluginHome() async throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let paths = try AppPaths(root: root, dshHome: root.appendingPathComponent("dsh-home"))
        try paths.prepare()
        let pluginManifest = paths.dshHome.appendingPathComponent("profiles/web/package.json")
        try FileManager.default.createDirectory(
            at: pluginManifest.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let originalPluginData = Data("{\"dependencies\":{\"plugin-a\":\"1.0.0\"}}".utf8)
        try originalPluginData.write(to: pluginManifest)

        let runner = InstallingCommandRunner()
        let toolchain = Toolchain(
            node: URL(fileURLWithPath: "/tools/bin/node"),
            npm: URL(fileURLWithPath: "/tools/bin/npm")
        )
        let store = VersionStore(paths: paths)
        let installer = PackageInstaller(
            paths: paths,
            toolchain: toolchain,
            store: store,
            commandRunner: runner
        )

        let installed = try await installer.installIfNeeded(version: "0.1.0-rc.6")

        XCTAssertEqual(installed, paths.runtime(version: "0.1.0-rc.6"))
        XCTAssertTrue(runner.arguments.contains("@deepseek-ai/dsh@0.1.0-rc.6"))
        XCTAssertTrue(runner.arguments.contains("pnpm@\(PackageInstaller.pnpmVersion)"))
        XCTAssertTrue(runner.arguments.contains("--loglevel=info"))
        XCTAssertEqual(runner.environment?["npm_config_color"], "false")
        XCTAssertEqual(runner.environment?["NO_COLOR"], "1")
        XCTAssertEqual(try Data(contentsOf: pluginManifest), originalPluginData)
        XCTAssertTrue(store.isUsable(version: "0.1.0-rc.6"))
    }
}

private final class InstallingCommandRunner: CommandRunning {
    private(set) var arguments: [String] = []
    private(set) var environment: [String: String]?

    func run(
        executable: URL,
        arguments: [String],
        currentDirectory: URL?,
        environment: [String: String]?
    ) async throws -> CommandResult {
        self.arguments = arguments
        self.environment = environment
        let directory = try XCTUnwrap(currentDirectory)
        let dsh = directory.appendingPathComponent("node_modules/@deepseek-ai/dsh/lib/bin.js")
        let pnpm = directory.appendingPathComponent("node_modules/.bin/pnpm")
        try FileManager.default.createDirectory(at: dsh.deletingLastPathComponent(), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: pnpm.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data().write(to: dsh)
        try Data("#!/bin/sh\n".utf8).write(to: pnpm)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: pnpm.path)
        return CommandResult(status: 0, output: "installed")
    }
}
