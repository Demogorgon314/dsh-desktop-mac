import Foundation

struct DownloadFileCoordinator {
    private struct Transfer {
        let temporaryURL: URL
        let destinationURL: URL
    }

    private let fileManager: FileManager
    private var transfers: [ObjectIdentifier: Transfer] = [:]

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    mutating func prepare(downloadID: ObjectIdentifier, destinationURL: URL) throws -> URL {
        let directory = destinationURL.deletingLastPathComponent()
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: directory.path, isDirectory: &isDirectory), isDirectory.boolValue else {
            throw CocoaError(.fileNoSuchFile)
        }

        let temporaryURL = directory.appendingPathComponent(
            ".dsh-download-\(UUID().uuidString).tmp",
            isDirectory: false
        )
        transfers[downloadID] = Transfer(
            temporaryURL: temporaryURL,
            destinationURL: destinationURL
        )
        return temporaryURL
    }

    mutating func finish(downloadID: ObjectIdentifier) throws -> URL? {
        guard let transfer = transfers.removeValue(forKey: downloadID) else { return nil }
        do {
            if fileManager.fileExists(atPath: transfer.destinationURL.path) {
                _ = try fileManager.replaceItemAt(
                    transfer.destinationURL,
                    withItemAt: transfer.temporaryURL
                )
            } else {
                try fileManager.moveItem(at: transfer.temporaryURL, to: transfer.destinationURL)
            }
            return transfer.destinationURL
        } catch {
            try? fileManager.removeItem(at: transfer.temporaryURL)
            throw error
        }
    }

    @discardableResult
    mutating func cancel(downloadID: ObjectIdentifier) -> Bool {
        guard let transfer = transfers.removeValue(forKey: downloadID) else { return false }
        try? fileManager.removeItem(at: transfer.temporaryURL)
        return true
    }
}
