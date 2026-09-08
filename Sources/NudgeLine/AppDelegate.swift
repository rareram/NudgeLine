// 앱 라이프사이클, 메뉴바 상태 아이템, 멀티 디스플레이 오버레이 패널 관리
import AppKit
import SwiftUI
import Combine

public final class AppDelegate: NSObject, NSApplicationDelegate {
    private var overlayPanels: [OverlayPanel] = []
    private var statusItem: NSStatusItem?
    private var cancellables = Set<AnyCancellable>()
    private var availableUpdate: UpdateService.ReleaseInfo? = nil

    private let settings = AppSettings.shared
    private let calendarService = CalendarService.shared

    // MARK: - 1. 앱 라이프사이클 (Application Lifecycle)
    public func applicationDidFinishLaunching(_ notification: Notification) {
        // 런치패드/Spotlight 노출 및 실행 후 Dock 아이콘 숨김 (.accessory)
        NSApp.setActivationPolicy(.accessory)

        setupStatusItem()
        setupOverlayPanels()
        observeDataChanges()

        // 캘린더 접근 권한 확인 및 초기 1회 즉시 데이터 로드
        if calendarService.isAuthorized() {
            calendarService.loadCalendars()
            calendarService.fetchEvents(settings: settings)
        } else {
            calendarService.requestAccess()
        }

        // 백그라운드에서 최신 릴리스 존재 여부를 조용히 확인합니다.
        UpdateService.shared.checkDiskBundleUpdate(force: true)
        checkLatestReleaseSilently()

        // 앱을 처음 실행했을 때 사용자가 설정을 인지할 수 있도록 설정창을 한 번 열어줍니다.
        checkFirstLaunchAndOpenSettings()
    }

    private func checkFirstLaunchAndOpenSettings() {
        let hasLaunchedBeforeKey = "hasLaunchedBefore"
        guard !UserDefaults.standard.bool(forKey: hasLaunchedBeforeKey) else { return }

        UserDefaults.standard.set(true, forKey: hasLaunchedBeforeKey)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
            self?.openSettings()
        }
    }
}

// MARK: - 2. 메뉴바 상태 아이템 구성 (Status Item & Menu)
extension AppDelegate {
    private func setupStatusItem() {
        if statusItem == nil {
            statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        }
        guard let button = statusItem?.button else { return }

        let config = NSImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        if let img = NSImage(systemSymbolName: "calendar.day.timeline.leading", accessibilityDescription: "NudgeLine")?.withSymbolConfiguration(config) {
            img.isTemplate = true
            button.image = img
        } else {
            button.title = "NudgeLine"
        }
        if case .pendingRestart(let version) = UpdateService.shared.updateState {
            button.toolTip = (settings.isDevBuild ? "NudgeLine (Dev)" : "NudgeLine") + " - \(L10n.tr(.newVersionReadyNotice(version), lang: settings.language))"
        } else {
            button.toolTip = settings.isDevBuild ? "NudgeLine (Dev)" : "NudgeLine"
        }

        let menu = NSMenu()

        let prefsItem = NSMenuItem(title: L10n.tr(.settings, lang: settings.language), action: #selector(openSettings), keyEquivalent: ",")
        menu.addItem(prefsItem)

        menu.addItem(NSMenuItem.separator())

        // 1) 로컬 디스크에 새 버전이 설치되어 재시작 대기 중인 경우 최상단 승격
        if case .pendingRestart(let version) = UpdateService.shared.updateState {
            let restartTitle = L10n.tr(.restartToApplyUpdate(version), lang: settings.language)
            let restartUpdateItem = NSMenuItem(title: restartTitle, action: #selector(restartApp), keyEquivalent: "r")
            menu.addItem(restartUpdateItem)
            menu.addItem(NSMenuItem.separator())
        } else if case .remoteAvailable(let version, _) = UpdateService.shared.updateState {
            // 2) 원격 GitHub 릴리스에 새 버전이 발견된 경우
            let updateTitle = L10n.tr(.newVersionAvailableMenu(version), lang: settings.language)
            let updateItem = NSMenuItem(title: updateTitle, action: #selector(openReleasePage), keyEquivalent: "")
            menu.addItem(updateItem)
            menu.addItem(NSMenuItem.separator())
        } else if let update = availableUpdate {
            let updateTitle = L10n.tr(.newVersionAvailableMenu(update.version), lang: settings.language)
            let updateItem = NSMenuItem(title: updateTitle, action: #selector(openReleasePage), keyEquivalent: "")
            menu.addItem(updateItem)
            menu.addItem(NSMenuItem.separator())
        }

        let restartItem = NSMenuItem(title: L10n.tr(.restart, lang: settings.language), action: #selector(restartApp), keyEquivalent: "")
        menu.addItem(restartItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: L10n.tr(.quit, lang: settings.language), action: #selector(quitApp), keyEquivalent: "q")
        menu.addItem(quitItem)

        statusItem?.menu = menu
    }
}

// MARK: - 3. 오버레이 패널 윈도우 관리 (Overlay Panels Setup)
extension AppDelegate {
    private func setupOverlayPanels() {
        overlayPanels.forEach { panel in
            panel.cleanup()
            panel.orderOut(nil)
            panel.close()
        }
        overlayPanels.removeAll()

        let allScreens = settings.showOnAllScreens ? NSScreen.screens : [NSScreen.main].compactMap { $0 }
        let validScreens = allScreens.filter { $0.frame.width > 100 && $0.frame.height > 100 }

        for screen in validScreens {
            let panel = OverlayPanel(screen: screen, settings: settings)
            panel.orderFrontRegardless()
            overlayPanels.append(panel)
        }
    }
}

// MARK: - 4. 시스템/디스플레이 변경 감시 (Combine Observers)
extension AppDelegate {
    private func observeDataChanges() {
        // 다중 디스플레이 표시 여부 변경 감지
        settings.$showOnAllScreens
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.setupOverlayPanels()
            }
            .store(in: &cancellables)

        // 디스플레이 연결/해제 및 해상도 변경 알림 수신
        NotificationCenter.default.publisher(for: NSApplication.didChangeScreenParametersNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.setupOverlayPanels()
            }
            .store(in: &cancellables)

        // 다국어 설정 변경 시 메뉴 항목 재생성
        settings.$language
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.setupStatusItem()
            }
            .store(in: &cancellables)

        // 업데이트 상태 변경 시 메뉴바 상태 항목 실시간 갱신
        UpdateService.shared.$updateState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.setupStatusItem()
            }
            .store(in: &cancellables)

        // 절전 모드 복귀 시 로컬 디스크 번들 확인 및 백그라운드 릴리스 검사
        NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.didWakeNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                UpdateService.shared.checkDiskBundleUpdate(force: true)
                self?.checkLatestReleaseSilently()
            }
            .store(in: &cancellables)

        // 24시간(86400초) 주기 백그라운드 릴리스 검사
        Timer.publish(every: 86400, on: .main, in: .default)
            .autoconnect()
            .sink { [weak self] _ in
                self?.checkLatestReleaseSilently()
            }
            .store(in: &cancellables)
    }
}

// MARK: - 5. 메뉴바 및 단축키 액션 핸들러 (Actions)
extension AppDelegate {
    // 환경설정 단일 윈도우 인스턴스 오픈
    @objc public func openSettings() {
        SettingsWindowController.shared.showSettings()
    }

    // 새 버전 릴리스 웹페이지 오픈
    @objc public func openReleasePage() {
        if case .remoteAvailable(_, let url) = UpdateService.shared.updateState {
            NSWorkspace.shared.open(url)
        } else if let url = availableUpdate?.url {
            NSWorkspace.shared.open(url)
        } else {
            NSWorkspace.shared.open(UpdateService.releasesURL)
        }
    }

    // 앱을 종료하고 0.3초 뒤 새 프로세스로 다시 실행합니다.
    @objc public func restartApp() {
        UpdateService.shared.restartApp()
    }

    @objc public func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}

// MARK: - 6. 백그라운드 릴리스 업데이트 검사
extension AppDelegate {
    private func checkLatestReleaseSilently() {
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.1"
        let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "60"

        UpdateService.shared.fetchLatestRelease { [weak self] result in
            guard let self = self, case .success(let release) = result else { return }
            if UpdateService.isNewerVersion(latest: release.version, current: appVersion, currentBuild: buildNumber) {
                self.availableUpdate = release
                self.setupStatusItem()
            }
        }
    }

    public static func isNewerVersion(latest: String, current: String, currentBuild: String) -> Bool {
        UpdateService.isNewerVersion(latest: latest, current: current, currentBuild: currentBuild)
    }
}
