import Foundation

// GitHub 릴리스 확인 및 버전 비교 서비스
public final class UpdateService: @unchecked Sendable {
    public static let shared = UpdateService()
    private init() {}

    public static let repoURL = URL(string: "https://github.com/rareram/NudgeLine")!
    public static let releasesURL = URL(string: "https://github.com/rareram/NudgeLine/releases")!
    public static let latestReleaseAPI = URL(string: "https://api.github.com/repos/rareram/NudgeLine/releases/latest")!

    public struct ReleaseInfo: Sendable, Equatable {
        public let version: String
        public let url: URL

        public init(version: String, url: URL) {
            self.version = version
            self.url = url
        }
    }

    public func fetchLatestRelease(completion: @escaping @MainActor @Sendable (Result<ReleaseInfo, Error>) -> Void) {
        var request = URLRequest(url: Self.latestReleaseAPI)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 10.0

        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }

            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let tagName = json["tag_name"] as? String else {
                DispatchQueue.main.async { completion(.failure(URLError(.cannotParseResponse))) }
                return
            }

            let version = tagName.trimmingCharacters(in: CharacterSet(charactersIn: "vV"))
            let releaseUrl = (json["html_url"] as? String).flatMap { URL(string: $0) } ?? Self.releasesURL

            let info = ReleaseInfo(version: version, url: releaseUrl)
            DispatchQueue.main.async {
                completion(.success(info))
            }
        }.resume()
    }

    public static func isNewerVersion(latest: String, current: String, currentBuild: String) -> Bool {
        let latestParts = latest.split(separator: ".").compactMap { Int($0) }
        var currentParts = current.split(separator: ".").compactMap { Int($0) }
        if currentParts.count == 2, let build = Int(currentBuild) {
            currentParts.append(build)
        }
        let maxCount = max(latestParts.count, currentParts.count)
        for i in 0..<maxCount {
            let l = i < latestParts.count ? latestParts[i] : 0
            let c = i < currentParts.count ? currentParts[i] : 0
            if l > c { return true }
            if l < c { return false }
        }
        return false
    }
}
