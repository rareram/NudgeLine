// 앱 라이프사이클, 메뉴바 상태 아이템, 멀티 디스플레이 오버레이 패널 관리
import AppKit
import SwiftUI
import Combine

public final class AppDelegate: NSObject, NSApplicationDelegate {
    private var overlayPanels: [OverlayPanel] = []
    private var statusItem: NSStatusItem?
    private var cancellables = Set<AnyCancellable>()

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
    }
}

// MARK: - 2. 메뉴바 상태 아이템 구성 (Status Item & Menu)
extension AppDelegate {
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        guard let button = statusItem?.button else { return }

        let config = NSImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        if let img = NSImage(systemSymbolName: "calendar.day.timeline.leading", accessibilityDescription: "NudgeLine")?.withSymbolConfiguration(config) {
            img.isTemplate = true
            button.image = img
        } else {
            button.title = "NudgeLine"
        }
        button.toolTip = settings.isDevBuild ? "NudgeLine (Dev)" : "NudgeLine"

        let menu = NSMenu()

        let prefsItem = NSMenuItem(title: L10n.tr(.settings, lang: settings.language), action: #selector(openSettings), keyEquivalent: ",")
        menu.addItem(prefsItem)

        let updateItem = NSMenuItem(title: L10n.tr(.refresh, lang: settings.language), action: #selector(refreshCalendars), keyEquivalent: "r")
        menu.addItem(updateItem)

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
    }
}

// MARK: - 5. 메뉴바 및 단축키 액션 핸들러 (Actions)
extension AppDelegate {
    @objc public func refreshCalendars() {
        calendarService.loadCalendars()
        calendarService.fetchEvents(settings: settings)
    }

    // 환경설정 단일 윈도우 인스턴스 오픈
    @objc public func openSettings() {
        SettingsWindowController.shared.showSettings()
    }

    @objc public func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
