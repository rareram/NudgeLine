// 환경설정 macOS 네이티브 NSToolbar 윈도우 컨트롤러 (Finder / RunCat 정통 표준)
import AppKit
import SwiftUI
import Combine

// MARK: - 1. 환경설정 4대 핵심 탭 모델 (1급 타입)
public enum SettingsTab: String, CaseIterable, Sendable {
    case timeline = "timeline"
    case appearance = "appearance"
    case schedule = "schedule"
    case general = "general"

    public func title(lang: AppLanguage) -> String {
        switch self {
        case .timeline: return L10n.tr(.tabTimeline, lang: lang)
        case .appearance: return L10n.tr(.tabAppearance, lang: lang)
        case .schedule: return L10n.tr(.tabSchedule, lang: lang)
        case .general: return L10n.tr(.tabGeneral, lang: lang)
        }
    }

    public var iconName: String {
        switch self {
        case .timeline: return "guidepoint.vertical.arrowtriangle.forward"
        case .appearance: return "calendar.day.timeline.leading"
        case .schedule: return "calendar.badge.clock"
        case .general: return "gear"
        }
    }
}

public final class SettingsWindowController: NSWindowController {
    public static let shared = SettingsWindowController()

    public static let windowWidth: CGFloat = 480.0
    public static let contentHorizontalPadding: CGFloat = 5.0
    public static let contentWidth: CGFloat = windowWidth - (contentHorizontalPadding * 2)

    public final class TabManager: ObservableObject {
        @Published public var selectedTab: SettingsTab = .timeline
    }

    public let tabManager = TabManager()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - 2. 초기화 및 라이프사이클 (Initialization)
    private init() {
        let settings = AppSettings.shared
        let calendarService = CalendarService.shared

        let hostingController = NSHostingController(
            rootView: SettingsView(
                settings: settings,
                calendarService: calendarService,
                tabManager: tabManager
            )
        )

        let window = NSWindow(contentViewController: hostingController)
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.title = L10n.tr(.settingsWindowTitle, lang: settings.language)
        window.toolbarStyle = .preference
        window.isReleasedWhenClosed = false
        window.center()

        super.init(window: window)

        setupToolbar(lang: settings.language)
        observeChanges()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupToolbar(lang: AppLanguage) {
        guard let window = self.window else { return }

        let toolbar = NSToolbar(identifier: "NudgeLineSettingsToolbar")
        toolbar.allowsUserCustomization = false
        toolbar.autosavesConfiguration = false
        toolbar.displayMode = .iconAndLabel
        toolbar.delegate = self
        toolbar.selectedItemIdentifier = NSToolbarItem.Identifier(tabManager.selectedTab.rawValue)

        window.toolbar = toolbar
    }

    private func observeChanges() {
        AppSettings.shared.$language
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newLang in
                guard let self = self, let window = self.window else { return }
                window.title = L10n.tr(.settingsWindowTitle, lang: newLang)
                if let toolbar = window.toolbar {
                    for item in toolbar.items {
                        if let tab = SettingsTab(rawValue: item.itemIdentifier.rawValue) {
                            item.label = tab.title(lang: newLang)
                        }
                    }
                }
            }
            .store(in: &cancellables)

        tabManager.$selectedTab
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.resizeWindow()
            }
            .store(in: &cancellables)

        CustomPetService.shared.$customPets
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.resizeWindow()
            }
            .store(in: &cancellables)
    }
}

// MARK: - 3. 공개 표시 인터페이스 (Public Interface)
extension SettingsWindowController {
    public func showSettings() {
        guard let window = self.window else { return }
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }
}

// MARK: - 4. 윈도우 프레임 애니메이션 리사이징 (Window Frame Resizing)
extension SettingsWindowController {
    public func resizeWindow() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self,
                  let window = self.window,
                  let contentView = window.contentView else { return }

            let idealSize = contentView.fittingSize
            guard idealSize.height > 0 else { return }

            let targetContentSize = NSSize(width: Self.windowWidth, height: idealSize.height)
            let newWindowFrame = window.frameRect(forContentRect: NSRect(origin: window.frame.origin, size: targetContentSize))
            let adjustedOrigin = NSPoint(x: window.frame.minX, y: window.frame.maxY - newWindowFrame.height)
            let finalFrame = NSRect(origin: adjustedOrigin, size: newWindowFrame.size)

            if abs(window.frame.height - finalFrame.height) > 1 {
                window.setFrame(finalFrame, display: true, animate: true)
            }
        }
    }
}

// MARK: - 5. NSToolbarDelegate 구현
extension SettingsWindowController: NSToolbarDelegate {
    public func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return SettingsTab.allCases.map { NSToolbarItem.Identifier($0.rawValue) }
    }

    public func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return toolbarDefaultItemIdentifiers(toolbar)
    }

    public func toolbarSelectableItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return toolbarDefaultItemIdentifiers(toolbar)
    }

    public func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        guard let tab = SettingsTab(rawValue: itemIdentifier.rawValue) else { return nil }

        let item = NSToolbarItem(itemIdentifier: itemIdentifier)
        item.label = tab.title(lang: AppSettings.shared.language)
        item.image = NSImage(systemSymbolName: tab.iconName, accessibilityDescription: item.label)
        item.target = self
        item.action = #selector(toolbarItemClicked(_:))
        return item
    }

    @objc private func toolbarItemClicked(_ sender: NSToolbarItem) {
        guard let tab = SettingsTab(rawValue: sender.itemIdentifier.rawValue) else { return }
        tabManager.selectedTab = tab
    }
}
