import Foundation
import XCTest
@testable import DSHLauncher

final class StatusPresentationTests: XCTestCase {
    func testWorkingPhasesShowActivityWithoutAnAction() throws {
        let phases: [RuntimePhase] = [
            .checkingVersion,
            .installing(version: "1.2.3"),
            .starting(version: "1.2.3"),
            .stopping,
        ]

        for phase in phases {
            let presentation = try XCTUnwrap(StatusPresentation(phase: phase))
            XCTAssertEqual(presentation.tone, .working)
            XCTAssertTrue(presentation.showsActivity)
            XCTAssertNil(presentation.actionTitle)
        }
    }

    func testInstallingPresentationIncludesVersion() throws {
        let presentation = try XCTUnwrap(StatusPresentation(phase: .installing(version: "0.1.0-rc.6")))

        XCTAssertEqual(presentation.title, "正在安装 DSH")
        XCTAssertTrue(presentation.detail.contains("0.1.0-rc.6"))
        XCTAssertTrue(presentation.showsInstallLog)
    }

    func testStoppedPresentationOffersStartAction() throws {
        let presentation = try XCTUnwrap(StatusPresentation(phase: .stopped))

        XCTAssertEqual(presentation.tone, .idle)
        XCTAssertEqual(presentation.actionTitle, "启动服务")
        XCTAssertFalse(presentation.showsActivity)
        XCTAssertFalse(presentation.showsInstallLog)
    }

    func testFailedPresentationPreservesErrorAndOffersRetry() throws {
        let message = "npm registry 暂时不可用。"
        let presentation = try XCTUnwrap(StatusPresentation(phase: .failed(message: message)))

        XCTAssertEqual(presentation.title, "无法启动 DSH")
        XCTAssertEqual(presentation.detail, message)
        XCTAssertEqual(presentation.tone, .error)
        XCTAssertEqual(presentation.actionTitle, "重试")
    }

    func testRunningPhaseDoesNotUseStatusPresentation() {
        let url = URL(string: "http://127.0.0.1:8080")!

        XCTAssertNil(StatusPresentation(phase: .running(version: "1.2.3", url: url)))
    }
}
