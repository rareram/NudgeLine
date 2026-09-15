// 앱 라이프사이클, 메뉴바 상태 아이템, 멀티 디스플레이 오버레이 패널 관리
import AppKit
import SwiftUI
import Combine

public final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private var overlayPanels: [OverlayPanel] = []
    private var statusItem: NSStatusItem?
    private var cancellables = Set<AnyCancellable>()
    private var globalMouseMonitor: Any?
    private var localMouseMonitor: Any?
    private var presentationCheckTimer: Timer?

    private let settings = AppSettings.shared
    private let calendarService = CalendarService.shared

    // MARK: - 1. 앱 라이프사이클 (Application Lifecycle)
    public func applicationDidFinishLaunching(_ notification: Notification) {
        // 런치패드/Spotlight 노출 및 실행 후 Dock 아이콘 숨김 (.accessory)
        NSApp.setActivationPolicy(.accessory)

        setupStatusItem()
        setupOverlayPanels()
        observeDataChanges()

        startGlobalMouseTracking()
        startPresentationTracking()
        scheduleBurstChecks()

        // 캘린더 접근 권한 확인 및 초기 1회 즉시 데이터 로드
        if calendarService.isAuthorized() {
            calendarService.loadCalendars()
            calendarService.fetchEvents(settings: settings)
        } else {
            calendarService.requestAccess()
        }

        // 백그라운드에서 최신 릴리스 존재 여부를 조용히 확인합니다.
        checkLatestReleaseSilently()

        // 앱을 처음 실행했을 때 사용자가 설정을 인지할 수 있도록 설정창을 한 번 열어줍니다.
        checkFirstLaunchAndOpenSettings()
    }

    public func applicationWillTerminate(_ notification: Notification) {
        stopGlobalMouseTracking()
        stopPresentationTracking()
        overlayPanels.forEach { $0.cleanup() }
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
        #if !APP_STORE
        if case .remoteAvailable(let version, _, _) = UpdateService.shared.updateState {
            button.toolTip = (settings.isDevBuild ? "NudgeLine (Dev)" : "NudgeLine") + " - \(L10n.tr(.newVersionAvailable(version), lang: settings.language))"
        } else {
            button.toolTip = settings.isDevBuild ? "NudgeLine (Dev)" : "NudgeLine"
        }
        #else
        button.toolTip = settings.isDevBuild ? "NudgeLine (Dev)" : "NudgeLine"
        #endif

        let menu = NSMenu()
        menu.delegate = self

        // 1. 환경설정
        let prefsItem = NSMenuItem(title: L10n.tr(.settings, lang: settings.language), action: #selector(openSettings), keyEquivalent: ",")
        menu.addItem(prefsItem)

        // 2. 새로 고침
        let refreshItem = NSMenuItem(title: L10n.tr(.refresh, lang: settings.language), action: #selector(refreshAction), keyEquivalent: "r")
        menu.addItem(refreshItem)

        #if !APP_STORE
        menu.addItem(NSMenuItem.separator())

        // 3. 업데이트 섹션
        if case .remoteAvailable(let version, _, _) = UpdateService.shared.updateState {
            let updateTitle = L10n.tr(.newVersionAvailableMenu(version), lang: settings.language)
            let updateItem = NSMenuItem(title: updateTitle, action: #selector(handleUpdateAction), keyEquivalent: "")
            menu.addItem(updateItem)
        } else {
            // 평상시: 업데이트 확인
            let checkUpdateItem = NSMenuItem(title: L10n.tr(.checkForUpdates, lang: settings.language), action: #selector(checkForUpdatesAction), keyEquivalent: "")
            menu.addItem(checkUpdateItem)
        }
        #endif

        menu.addItem(NSMenuItem.separator())

        // 4. 종료
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

        // 패널 생성 직후 마우스 호버 상태 및 전체화면 은폐 즉시 동기화
        dispatchMouseMoved()
        scheduleBurstChecks()
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

        // 전체화면 은폐 옵션 변경 즉시 반영
        settings.$hideOnFullScreen
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.scheduleBurstChecks()
            }
            .store(in: &cancellables)

        // 스페이스 및 활성 앱 전환 시 전체화면 은폐 감지
        let wsCenter = NSWorkspace.shared.notificationCenter
        Publishers.Merge(
            wsCenter.publisher(for: NSWorkspace.activeSpaceDidChangeNotification),
            wsCenter.publisher(for: NSWorkspace.didActivateApplicationNotification)
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] _ in
            self?.scheduleBurstChecks()
        }
        .store(in: &cancellables)

        // 절전 진입 시 모니터링 중단으로 이벤트 소모 차단
        Publishers.Merge(
            wsCenter.publisher(for: NSWorkspace.willSleepNotification),
            wsCenter.publisher(for: NSWorkspace.screensDidSleepNotification)
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] _ in
            self?.stopGlobalMouseTracking()
            self?.stopPresentationTracking()
        }
        .store(in: &cancellables)

        // 절전 해제 시 모니터링 복구 및 화면 상태 재검사
        Publishers.Merge(
            wsCenter.publisher(for: NSWorkspace.didWakeNotification),
            wsCenter.publisher(for: NSWorkspace.screensDidWakeNotification)
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] _ in
            self?.startGlobalMouseTracking()
            self?.startPresentationTracking()
            self?.scheduleBurstChecks()
        }
        .store(in: &cancellables)

        // 다국어 설정 변경 시 메뉴 항목 재생성
        settings.$language
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.setupStatusItem()
            }
            .store(in: &cancellables)

        #if !APP_STORE
        // 업데이트 상태 변경 시 메뉴바 상태 항목 실시간 갱신
        UpdateService.shared.$updateState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.setupStatusItem()
            }
            .store(in: &cancellables)

        // 절전 모드 복귀 시 백그라운드 릴리스 검사
        NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.didWakeNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
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
        #endif
    }
}

// MARK: - 5. 메뉴바 및 단축키 액션 핸들러 (Actions)
extension AppDelegate {
    // 원격 캘린더 동기화 신호 전송 및 로컬 일정 즉시 새로고침
    @objc public func refreshAction() {
        CalendarService.shared.refreshSources()
        CalendarService.shared.loadCalendars()
        CalendarService.shared.fetchEvents()
    }

    // 환경설정 단일 윈도우 인스턴스 오픈
    @objc public func openSettings() {
        SettingsWindowController.shared.showSettings()
    }

    #if !APP_STORE
    // 새 버전 릴리스 웹페이지 오픈 또는 인앱 다운로드 실행
    @objc public func handleUpdateAction() {
        if case .remoteAvailable(let version, let url, let zipURL) = UpdateService.shared.updateState {
            let release = UpdateService.ReleaseInfo(version: version, url: url, zipURL: zipURL)
            if release.zipURL != nil {
                let alert = NSAlert()
                alert.messageText = "NudgeLine"
                alert.informativeText = L10n.tr(.newVersionAvailable(release.version), lang: settings.language)
                alert.alertStyle = .informational
                alert.addButton(withTitle: L10n.tr(.updateNowInApp, lang: settings.language))
                alert.addButton(withTitle: L10n.tr(.viewRelease, lang: settings.language))
                alert.addButton(withTitle: L10n.tr(.cancelButton, lang: settings.language))

                let resp = alert.runModal()
                if resp == .alertFirstButtonReturn {
                    UpdateService.shared.startInAppDownload(release: release)
                } else if resp == .alertSecondButtonReturn {
                    NSWorkspace.shared.open(release.url)
                }
            } else {
                NSWorkspace.shared.open(release.url)
            }
        } else {
            NSWorkspace.shared.open(UpdateService.releasesURL)
        }
    }

    // 수동 업데이트 확인 액션
    @objc public func checkForUpdatesAction() {
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.1"
        let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "60"

        UpdateService.shared.fetchLatestRelease { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let release):
                if UpdateService.isNewerVersion(latest: release.version, current: appVersion, currentBuild: buildNumber) {
                    self.setupStatusItem()
                    self.handleUpdateAction()
                } else {
                    self.setupStatusItem()
                    let alert = NSAlert()
                    alert.messageText = "NudgeLine"
                    alert.informativeText = "\(L10n.tr(.upToDate, lang: self.settings.language))\n(Version \(appVersion), Build \(buildNumber))"
                    alert.alertStyle = .informational
                    alert.addButton(withTitle: "OK")
                    alert.runModal()
                }
            case .failure:
                let alert = NSAlert()
                alert.messageText = "NudgeLine"
                alert.informativeText = L10n.tr(.checkUpdateFailed, lang: self.settings.language)
                alert.alertStyle = .warning
                alert.addButton(withTitle: "OK")
                alert.runModal()
            }
        }
    }
    #endif

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
        #if !APP_STORE
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.1"
        let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "60"

        UpdateService.shared.fetchLatestRelease { [weak self] result in
            guard let self = self, case .success(let release) = result else { return }
            if UpdateService.isNewerVersion(latest: release.version, current: appVersion, currentBuild: buildNumber) {
                self.setupStatusItem()
            }
        }
        #endif
    }
}

// MARK: - 7. 중앙 마우스 트래킹 및 전체화면 감지
extension AppDelegate {
    // 전역 및 로컬 마우스 이벤트 감시 등록
    private func startGlobalMouseTracking() {
        stopGlobalMouseTracking()
        let mask: NSEvent.EventTypeMask = [.mouseMoved, .leftMouseDragged, .rightMouseDragged, .leftMouseDown, .rightMouseDown]
        globalMouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: mask) { [weak self] _ in
            DispatchQueue.main.async {
                self?.dispatchMouseMoved()
            }
        }
        localMouseMonitor = NSEvent.addLocalMonitorForEvents(matching: mask) { [weak self] event in
            self?.dispatchMouseMoved()
            return event
        }
        dispatchMouseMoved()
    }

    // 마우스 이벤트 감시 해제
    private func stopGlobalMouseTracking() {
        if let monitor = globalMouseMonitor {
            NSEvent.removeMonitor(monitor)
            globalMouseMonitor = nil
        }
        if let monitor = localMouseMonitor {
            NSEvent.removeMonitor(monitor)
            localMouseMonitor = nil
        }
    }

    // 모든 패널에 현재 마우스 좌표 일괄 전송
    private func dispatchMouseMoved() {
        let mouseLoc = NSEvent.mouseLocation
        for panel in overlayPanels {
            panel.handleMouseMoved(at: mouseLoc)
        }
    }

    // 5초 주기 전체화면 검사 타이머 가동
    private func startPresentationTracking() {
        stopPresentationTracking()
        let timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.checkFullScreenAcrossPanels()
        }
        RunLoop.main.add(timer, forMode: .common)
        presentationCheckTimer = timer
    }

    // 전체화면 검사 타이머 해제
    private func stopPresentationTracking() {
        presentationCheckTimer?.invalidate()
        presentationCheckTimer = nil
    }

    // 스페이스 및 앱 전환 시 즉각 반영 위한 버스트 검사
    private func scheduleBurstChecks() {
        checkFullScreenAcrossPanels()
        let delays: [Double] = [0.1, 0.3, 0.5]
        for delay in delays {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.checkFullScreenAcrossPanels()
            }
        }
    }

    // 시스템 윈도우 목록 1회 조회 후 각 패널 전체화면 여부 갱신
    private func checkFullScreenAcrossPanels() {
        let currentPid = NSRunningApplication.current.processIdentifier
        guard settings.hideOnFullScreen else {
            for panel in overlayPanels {
                panel.updateFullScreenState(windowList: [], currentPid: currentPid)
            }
            return
        }

        let windowList = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] ?? []
        for panel in overlayPanels {
            panel.updateFullScreenState(windowList: windowList, currentPid: currentPid)
        }
    }
}
