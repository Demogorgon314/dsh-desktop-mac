import WebKit
import XCTest
@testable import DSHLauncher

final class WebDownloadTests: XCTestCase {
    @MainActor
    func testMainWindowHandlesWebKitDownloadLifecycle() {
        let controller = MainWindowController()

        XCTAssertTrue(controller.responds(to: #selector(WKNavigationDelegate.webView(
            _:navigationAction:didBecome:
        ))))
        XCTAssertTrue(controller.responds(to: #selector(WKNavigationDelegate.webView(
            _:navigationResponse:didBecome:
        ))))
        XCTAssertTrue(controller.responds(to: #selector(WKDownloadDelegate.download(
            _:decideDestinationUsing:suggestedFilename:completionHandler:
        ))))
    }

    func testDownloadFileCoordinatorMovesCompletedDownloadToDestination() throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let destination = directory.appendingPathComponent("session.zip")
        let download = NSObject()
        var coordinator = DownloadFileCoordinator()

        let temporary = try coordinator.prepare(
            downloadID: ObjectIdentifier(download),
            destinationURL: destination
        )
        try Data("archive".utf8).write(to: temporary)
        let completed = try coordinator.finish(downloadID: ObjectIdentifier(download))

        XCTAssertEqual(completed, destination)
        XCTAssertEqual(try Data(contentsOf: destination), Data("archive".utf8))
        XCTAssertFalse(FileManager.default.fileExists(atPath: temporary.path))
    }

    func testDownloadFileCoordinatorReplacesConfirmedDestinationOnlyAfterCompletion() throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let destination = directory.appendingPathComponent("session.zip")
        try Data("old".utf8).write(to: destination)
        let download = NSObject()
        var coordinator = DownloadFileCoordinator()

        let temporary = try coordinator.prepare(
            downloadID: ObjectIdentifier(download),
            destinationURL: destination
        )
        XCTAssertEqual(try Data(contentsOf: destination), Data("old".utf8))
        try Data("new".utf8).write(to: temporary)
        _ = try coordinator.finish(downloadID: ObjectIdentifier(download))

        XCTAssertEqual(try Data(contentsOf: destination), Data("new".utf8))
    }

    func testDownloadFileCoordinatorRejectsMissingDestinationDirectory() {
        let download = NSObject()
        var coordinator = DownloadFileCoordinator()
        let destination = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
            .appendingPathComponent("session.zip")

        XCTAssertThrowsError(try coordinator.prepare(
            downloadID: ObjectIdentifier(download),
            destinationURL: destination
        ))
    }

    func testDownloadFileCoordinatorCleansUpFailedDownloadWithoutTreatingPanelCancellationAsFailure() throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let download = NSObject()
        var coordinator = DownloadFileCoordinator()
        let temporary = try coordinator.prepare(
            downloadID: ObjectIdentifier(download),
            destinationURL: directory.appendingPathComponent("session.zip")
        )
        try Data("partial".utf8).write(to: temporary)

        XCTAssertTrue(coordinator.cancel(downloadID: ObjectIdentifier(download)))
        XCTAssertFalse(FileManager.default.fileExists(atPath: temporary.path))
        XCTAssertFalse(coordinator.cancel(downloadID: ObjectIdentifier(NSObject())))
    }

    private func makeTemporaryDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("DSHDesktopTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: false)
        return directory
    }
}
