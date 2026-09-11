import Foundation
import AppKit

// GitHub 릴리스 확인, 로컬 번들 교체 감지 및 버전 비교 서비스
public final class UpdateService: ObservableObject, @unchecked Sendable {
    public static let shared = UpdateService()
    private init() {}

    public static let repoURL = URL(string: "https://github.com/rareram/NudgeLine")!
    public static let releasesURL = URL(string: "https://github.com/rareram/NudgeLine/releases")!
    public static let latestReleaseAPI = URL(string: "https://api.github.com/repos/rareram/NudgeLine/releases/latest")!
    public static let appStoreURL: URL? = URL(string: "macappstore://showUpdatesPage")

    public enum UpdateState: Equatable, Sendable {
        case idle
        case pendingRestart(version: String)
        case remoteAvailable(version: String, url: URL)
    }

    @Published public private(set) var updateState: UpdateState = .idle
    private var lastDiskCheckTime: Date = .distantPast

    public struct ReleaseInfo: Sendable, Equatable {
        public let version: String
        public let url: URL

        public init(version: String, url: URL) {
            self.version = version
            self.url = url
        }
    }

    // MARK: - 1. 로컬 디스크 번들 교체 감지 (Zero-Timer Event-driven)
    @discardableResult
    public func checkDiskBundleUpdate(force: Bool = false) -> Bool {
        #if APP_STORE
        return false
        #else
        let now = Date()
        if !force && now.timeIntervalSince(lastDiskCheckTime) < 30 {
            if case .pendingRestart = updateState { return true }
            return false
        }
        lastDiskCheckTime = now

        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.1"
        let currentBuild = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "0"

        let plistURL = Bundle.main.bundleURL.appendingPathComponent("Contents/Info.plist")
        guard let data = try? Data(contentsOf: plistURL),
              let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] else {
            return false
        }

        let diskVersion = plist["CFBundleShortVersionString"] as? String ?? ""
        let diskBuild = plist["CFBundleVersion"] as? String ?? ""

        guard !diskVersion.isEmpty || !diskBuild.isEmpty else { return false }

        if Self.isDiskNewer(diskVersion: diskVersion, diskBuild: diskBuild, currentVersion: currentVersion, currentBuild: currentBuild) {
            let displayVersion = diskBuild.isEmpty ? diskVersion : (diskVersion.contains(".") && diskVersion.split(separator: ".").count == 2 ? "\(diskVersion).\(diskBuild)" : diskVersion)
            let newState = UpdateState.pendingRestart(version: displayVersion)
            if Thread.isMainThread {
                self.updateState = newState
            } else {
                DispatchQueue.main.async { [weak self] in
                    self?.updateState = newState
                }
            }
            return true
        }
        return false
        #endif
    }

    public static func isDiskNewer(diskVersion: String, diskBuild: String, currentVersion: String, currentBuild: String) -> Bool {
        let diskTag = diskVersion.split(separator: ".").count == 2 && !diskBuild.isEmpty ? "\(diskVersion).\(diskBuild)" : diskVersion
        let latestParts = diskTag.split(separator: ".").compactMap { Int($0) }
        var currentParts = currentVersion.split(separator: ".").compactMap { Int($0) }
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

    // MARK: - 2. 사용자 액션 (재시작 또는 앱스토어 이동)
    public func applyOrRestart() {
        #if APP_STORE
        if let url = Self.appStoreURL {
            NSWorkspace.shared.open(url)
        }
        #else
        restartApp()
        #endif
    }

    public func restartApp() {
        #if APP_STORE
        // App Store 환경에서는 프로세스 자가 실행이 금지됨
        #else
        let bundleURL = Bundle.main.bundleURL
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/sh")
        task.arguments = ["-c", "sleep 0.3 && open \"$1\"", "--", bundleURL.path]
        try? task.run()
        NSApplication.shared.terminate(nil)
        #endif
    }

    // MARK: - 3. 원격 GitHub Releases 비동기 조회
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
                if case .idle = self.updateState {
                    let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.1"
                    let currentBuild = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "0"
                    if Self.isNewerVersion(latest: version, current: currentVersion, currentBuild: currentBuild) {
                        self.updateState = .remoteAvailable(version: version, url: releaseUrl)
                    }
                }
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
