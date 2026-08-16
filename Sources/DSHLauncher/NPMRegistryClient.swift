import Foundation

protocol LatestVersionProviding {
    func latestVersion() async throws -> String
}

struct NPMRegistryClient: LatestVersionProviding {
    private struct Metadata: Decodable {
        let version: String
    }

    private let session: URLSession
    private let endpoint: URL

    init(
        session: URLSession = .shared,
        endpoint: URL = URL(string: "https://registry.npmjs.org/%40deepseek-ai%2Fdsh/latest")!
    ) {
        self.session = session
        self.endpoint = endpoint
    }

    func latestVersion() async throws -> String {
        var request = URLRequest(url: endpoint)
        request.timeoutInterval = 8
        request.cachePolicy = .reloadIgnoringLocalCacheData
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw LauncherError.invalidRegistryResponse
        }
        let metadata = try JSONDecoder().decode(Metadata.self, from: data)
        guard isSafeVersion(metadata.version) else { throw LauncherError.invalidRegistryResponse }
        return metadata.version
    }

    private func isSafeVersion(_ version: String) -> Bool {
        !version.isEmpty && version.unicodeScalars.allSatisfy {
            CharacterSet.alphanumerics.union(CharacterSet(charactersIn: ".+-_")).contains($0)
        }
    }
}
