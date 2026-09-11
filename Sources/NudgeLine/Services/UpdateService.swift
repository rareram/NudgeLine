import Foundation
import AppKit

// GitHub 릴리스 확인, 인앱 백그라운드 다운로드 및 무손실 자가 교체 서비스
public final class UpdateService: NSObject, ObservableObject, URLSessionDownloadDelegate, @unchecked Sendable {
    public static let shared = UpdateService()

    public static let repoURL = URL(string: "https://github.com/rareram/NudgeLine")!
    public static let releasesURL = URL(string: "https://github.com/rareram/NudgeLine/releases")!
    public static let latestReleaseAPI = URL(string: "https://api.github.com/repos/rareram/NudgeLine/releases/latest")!

    public enum UpdateState: Equatable, Sendable {
        case idle
        case remoteAvailable(version: String, url: URL, zipURL: URL?)
        case downloading(version: String, progress: Double)
    }

    @Published public private(set) var updateState: UpdateState = .idle

    public struct ReleaseInfo: Sendable, Equatable {
        public let version: String
        public let url: URL
        public let zipURL: URL?

        public init(version: String, url: URL, zipURL: URL? = nil) {
            self.version = version
            self.url = url
            self.zipURL = zipURL
        }
    }

    // 인앱 다운로드 진행 상태 UI 컴포넌트
    private var activeDownloadTask: URLSessionDownloadTask?
    private var progressWindow: NSWindow?
    private var progressIndicator: NSProgressIndicator?
    private var statusLabel: NSTextField?
    private var percentLabel: NSTextField?
    private var pendingRelease: ReleaseInfo?

    private override init() {
        super.init()
    }

    // MARK: - 1. 프로세스 단순 재기동 (Relaunch)
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

    // MARK: - 2. 인앱 원클릭 다운로드 및 자동 설치 파이프라인
    public func startInAppDownload(release: ReleaseInfo) {
        guard let zipURL = release.zipURL else {
            // ZIP 에셋이 없으면 브라우저로 릴리스 페이지 오픈 폴백
            NSWorkspace.shared.open(release.url)
            return
        }

        self.pendingRelease = release
        self.updateState = .downloading(version: release.version, progress: 0.0)

        showProgressUI(version: release.version)

        let sessionConfig = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfig, delegate: self, delegateQueue: OperationQueue.main)
        let task = session.downloadTask(with: zipURL)
        self.activeDownloadTask = task
        task.resume()
    }

    // 네이티브 진행률 플로팅 윈도우 표시
    private func showProgressUI(version: String) {
        progressWindow?.close()

        let width: CGFloat = 360
        let height: CGFloat = 130
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: width, height: height),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "NudgeLine Update"
        window.center()
        window.isReleasedWhenClosed = false
        window.level = .floating

        let contentView = NSView(frame: NSRect(x: 0, y: 0, width: width, height: height))
        contentView.wantsLayer = true

        let iconView = NSImageView(frame: NSRect(x: 18, y: height - 58, width: 44, height: 44))
        if let appIcon = NSImage(named: NSImage.applicationIconName) ?? NSApp.applicationIconImage {
            iconView.image = appIcon
        } else {
            let config = NSImage.SymbolConfiguration(pointSize: 32, weight: .regular)
            iconView.image = NSImage(systemSymbolName: "arrow.down.circle.fill", accessibilityDescription: "Updating")?.withSymbolConfiguration(config)
        }
        contentView.addSubview(iconView)

        let titleLabel = NSTextField(labelWithString: L10n.tr(.downloadingUpdate(version)))
        titleLabel.font = NSFont.systemFont(ofSize: 12, weight: .semibold)
        titleLabel.frame = NSRect(x: 72, y: height - 36, width: width - 88, height: 18)
        contentView.addSubview(titleLabel)
        self.statusLabel = titleLabel

        let pIndicator = NSProgressIndicator(frame: NSRect(x: 72, y: height - 62, width: width - 148, height: 14))
        pIndicator.isIndeterminate = false
        pIndicator.minValue = 0.0
        pIndicator.maxValue = 100.0
        pIndicator.doubleValue = 0.0
        contentView.addSubview(pIndicator)
        self.progressIndicator = pIndicator

        let pctLabel = NSTextField(labelWithString: "0%")
        pctLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .regular)
        pctLabel.alignment = .right
        pctLabel.textColor = NSColor.secondaryLabelColor
        pctLabel.frame = NSRect(x: width - 70, y: height - 64, width: 52, height: 16)
        contentView.addSubview(pctLabel)
        self.percentLabel = pctLabel

        let cancelButton = NSButton(title: L10n.tr(.cancelButton), target: self, action: #selector(cancelDownload))
        cancelButton.bezelStyle = .rounded
        cancelButton.frame = NSRect(x: width - 90, y: 12, width: 74, height: 26)
        contentView.addSubview(cancelButton)

        window.contentView = contentView
        self.progressWindow = window
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    @objc private func cancelDownload() {
        activeDownloadTask?.cancel()
        activeDownloadTask = nil
        progressWindow?.close()
        progressWindow = nil
        updateState = .idle
    }

    // MARK: - 3. 원격 GitHub Releases 비동기 조회
    public func fetchLatestRelease(completion: @escaping @MainActor @Sendable (Result<ReleaseInfo, Error>) -> Void) {
        var request = URLRequest(url: Self.latestReleaseAPI)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 10.0

        URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            guard let self = self else { return }
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

            // Release Assets 중 .zip 확장자를 가진 바이너리 다운로드 URL 추출
            var zipDownloadURL: URL?
            if let assets = json["assets"] as? [[String: Any]] {
                for asset in assets {
                    if let name = asset["name"] as? String,
                       name.hasSuffix(".zip"),
                       let downloadStr = asset["browser_download_url"] as? String,
                       let assetURL = URL(string: downloadStr) {
                        zipDownloadURL = assetURL
                        break
                    }
                }
            }

            let info = ReleaseInfo(version: version, url: releaseUrl, zipURL: zipDownloadURL)
            DispatchQueue.main.async {
                let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.1"
                let currentBuild = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "0"
                if Self.isNewerVersion(latest: version, current: currentVersion, currentBuild: currentBuild) {
                    self.updateState = .remoteAvailable(version: version, url: releaseUrl, zipURL: zipDownloadURL)
                }
                completion(.success(info))
            }
        }.resume()
    }

    // MARK: - 4. URLSessionDownloadDelegate 이벤트 수신
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard totalBytesExpectedToWrite > 0 else { return }
        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        let percent = Int(progress * 100)

        DispatchQueue.main.async { [weak self] in
            self?.progressIndicator?.doubleValue = progress * 100.0
            self?.percentLabel?.stringValue = "\(percent)%"
        }
    }

    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        DispatchQueue.main.async { [weak self] in
            self?.statusLabel?.stringValue = L10n.tr(.installingAndRestarting)
            self?.progressIndicator?.isIndeterminate = true
            self?.progressIndicator?.startAnimation(nil)
            self?.percentLabel?.stringValue = ""
        }

        let uniqueId = UUID().uuidString
        let tempZipURL = URL(fileURLWithPath: "/tmp/nudgeline_pkg_\(uniqueId).zip")
        let extractDir = URL(fileURLWithPath: "/tmp/nudgeline_extract_\(uniqueId)")

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            do {
                if FileManager.default.fileExists(atPath: tempZipURL.path) {
                    try FileManager.default.removeItem(at: tempZipURL)
                }
                if FileManager.default.fileExists(atPath: extractDir.path) {
                    try FileManager.default.removeItem(at: extractDir)
                }

                try FileManager.default.copyItem(at: location, to: tempZipURL)
                try FileManager.default.createDirectory(at: extractDir, withIntermediateDirectories: true)

                // macOS ditto를 사용하여 권한과 코드 서명을 100% 무손실 보존하며 압축 해제
                let unzipProcess = Process()
                unzipProcess.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
                unzipProcess.arguments = ["-xk", tempZipURL.path, extractDir.path]
                try unzipProcess.run()
                unzipProcess.waitUntilExit()

                guard unzipProcess.terminationStatus == 0 else {
                    throw NSError(domain: "UpdateError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to extract package via ditto."])
                }

                // 압축 해제된 폴더 내 NudgeLine.app 또는 *.app 탐색
                let contents = try FileManager.default.contentsOfDirectory(atPath: extractDir.path)
                guard let appBundleName = contents.first(where: { $0.hasSuffix(".app") }) else {
                    throw NSError(domain: "UpdateError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Extracted update is missing application bundle."])
                }
                let extractedAppURL = extractDir.appendingPathComponent(appBundleName)

                // 타깃 설치 경로 확인
                var targetAppPath = Bundle.main.bundleURL.path
                if !targetAppPath.hasSuffix(".app") {
                    targetAppPath = "/Applications/NudgeLine.app"
                }

                // 백그라운드 교체 및 재실행 스크립트 실행
                // 1) 0.6초 대기 (현재 프로세스 안전 종료)
                // 2) 기존 앱 삭제 및 ditto로 새 앱 무손실 복사
                // 3) xattr 격리 속성 해제 (Gatekeeper 경고 방지)
                // 4) open 명령어로 새 앱 실행 및 임시 파일 정리
                let shellScript = """
                sleep 0.6
                rm -rf "\(targetAppPath)"
                /usr/bin/ditto "\(extractedAppURL.path)" "\(targetAppPath)"
                /usr/bin/xattr -d -r com.apple.quarantine "\(targetAppPath)" 2>/dev/null || true
                /usr/bin/open "\(targetAppPath)"
                rm -rf "\(extractDir.path)" "\(tempZipURL.path)"
                """

                DispatchQueue.main.async {
                    self.progressWindow?.close()
                    self.progressWindow = nil

                    let relaunchProcess = Process()
                    relaunchProcess.executableURL = URL(fileURLWithPath: "/bin/sh")
                    relaunchProcess.arguments = ["-c", shellScript]

                    do {
                        try relaunchProcess.run()
                        NSApp.terminate(nil)
                    } catch {
                        self.handleUpdateFailure(error: error)
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.progressWindow?.close()
                    self.progressWindow = nil
                    self.handleUpdateFailure(error: error)
                }
            }
        }
    }

    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let error = error else { return }
        if (error as NSError).code == NSURLErrorCancelled { return }

        DispatchQueue.main.async { [weak self] in
            self?.progressWindow?.close()
            self?.progressWindow = nil
            self?.handleUpdateFailure(error: error)
        }
    }

    private func handleUpdateFailure(error: Error) {
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.messageText = L10n.tr(.inAppUpdateFailed)
        alert.informativeText = "\(error.localizedDescription)\n\n\(L10n.tr(.viewRelease))?"
        alert.alertStyle = .warning
        alert.addButton(withTitle: L10n.tr(.viewRelease))
        alert.addButton(withTitle: L10n.tr(.cancelButton))

        let resp = alert.runModal()
        if resp == .alertFirstButtonReturn, let release = pendingRelease {
            NSWorkspace.shared.open(release.url)
        }
    }

    // MARK: - 5. 시맨틱 버전 비교 유틸리티
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
