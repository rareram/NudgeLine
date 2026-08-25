// 화면 가장자리 상주 플로팅 NSPanel 및 마우스 무간섭 패스스루 제어
import AppKit
import SwiftUI
import Combine

public final class OverlayPanel: NSPanel {
    private let targetScreen: NSScreen
    private let settings: AppSettings
    private var cancellables = Set<AnyCancellable>()
    private var isMouseInActiveZone: Bool = false
    private var mouseTrackingTimer: Timer?

    public init(screen: NSScreen, settings: AppSettings) {
        self.targetScreen = screen
        self.settings = settings

        super.init(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        self.level = .floating
        self.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = false
        self.ignoresMouseEvents = false
        self.acceptsMouseMovedEvents = true

        let rootView = TimelineBarView(settings: settings, calendarService: CalendarService.shared)
        let hostingView = EdgePassthroughHostingView(rootView: rootView, settings: settings)
        self.contentView = hostingView

        updateFrame()
        observeNotifications()
        startMouseTracking()
    }

    deinit {
        mouseTrackingTimer?.invalidate()
    }

    // 대상 디스플레이 기준 패널 프레임 크기 및 위치 재계산
    public func updateFrame() {
        let screen = targetScreen
        let visibleFrame = screen.visibleFrame
        let fullFrame = screen.frame
        let maxThickness: CGFloat = max(settings.barWidth, settings.hoverWidth)
        let panelThickness: CGFloat = max(maxThickness + 54, 64.0)

        let newFrame: NSRect
        switch settings.barPosition {
        case .left:
            newFrame = NSRect(
                x: fullFrame.minX,
                y: visibleFrame.minY,
                width: panelThickness,
                height: visibleFrame.height
            )
        case .right:
            newFrame = NSRect(
                x: fullFrame.maxX - panelThickness,
                y: visibleFrame.minY,
                width: panelThickness,
                height: visibleFrame.height
            )
        case .bottom:
            newFrame = NSRect(
                x: visibleFrame.minX,
                y: fullFrame.minY,
                width: visibleFrame.width,
                height: panelThickness
            )
        }

        if self.frame != newFrame {
            self.setFrame(newFrame, display: true)
        }
    }

    private var lastMouseLoc: NSPoint = .zero

    // 30Hz 저전력 마우스 좌표 감시 루프 (패스스루 및 펫 근접 감지)
    private func startMouseTracking() {
        mouseTrackingTimer?.invalidate()
        let timer = Timer(timeInterval: 0.033, repeats: true) { [weak self] _ in
            self?.checkMouseProximityAndHit()
        }
        RunLoop.main.add(timer, forMode: .common)
        mouseTrackingTimer = timer
    }

    // 마우스 좌표 분석을 통한 무간섭 패스스루 및 펫 근접 제어
    private func checkMouseProximityAndHit() {
        guard settings.isBarVisible else { return }
        let mouseLoc = NSEvent.mouseLocation
        if mouseLoc == lastMouseLoc { return }
        lastMouseLoc = mouseLoc
        let panelRect = self.frame

        // 1. 물리 타임라인 바 영역 진입 여부 판정 (최소 12px의 클릭 감도 마진 보장)
        let effectiveThickness = settings.expandOnHover ? max(settings.barWidth, settings.hoverWidth) : settings.barWidth
        let hitMargin: CGFloat = max(effectiveThickness, 12.0)
        let isInsideBar: Bool

        switch settings.barPosition {
        case .left:
            let barRect = NSRect(x: panelRect.minX, y: panelRect.minY, width: hitMargin, height: panelRect.height)
            isInsideBar = barRect.contains(mouseLoc)
        case .right:
            let barRect = NSRect(x: panelRect.maxX - hitMargin, y: panelRect.minY, width: hitMargin, height: panelRect.height)
            isInsideBar = barRect.contains(mouseLoc)
        case .bottom:
            let barRect = NSRect(x: panelRect.minX, y: panelRect.minY, width: panelRect.width, height: hitMargin)
            isInsideBar = barRect.contains(mouseLoc)
        }

        // 바 외부 영역은 WindowServer 레벨에서 ignoresMouseEvents를 true로 토글하여 클릭 관통 보장
        if isInsideBar {
            if self.ignoresMouseEvents {
                self.ignoresMouseEvents = false
            }
        } else {
            if !self.ignoresMouseEvents {
                self.ignoresMouseEvents = true
            }
        }

        // 2. 펫 마스코트 근접 감지 (숨김 애니메이션 트리거)
        guard settings.isPetEnabled else {
            if settings.isPetProximityHovered {
                settings.isPetProximityHovered = false
            }
            return
        }

        let now = Date()
        let dayStart = settings.startDate(for: now)
        let dayEnd = settings.endDate(for: now)
        let totalSec = max(60, dayEnd.timeIntervalSince(dayStart))
        let curSec = now.timeIntervalSince(dayStart)

        if curSec >= 0 && curSec <= totalSec {
            let progress = CGFloat(curSec / totalSec)
            let petScreenPoint: CGPoint

            switch settings.barPosition {
            case .left:
                let petY = panelRect.maxY - (progress * panelRect.height)
                let petX = panelRect.minX + 22.0
                petScreenPoint = CGPoint(x: petX, y: petY)
            case .right:
                let petY = panelRect.maxY - (progress * panelRect.height)
                let petX = panelRect.maxX - 22.0
                petScreenPoint = CGPoint(x: petX, y: petY)
            case .bottom:
                let petX = panelRect.minX + (progress * panelRect.width)
                let petY = panelRect.minY + 16.0
                petScreenPoint = CGPoint(x: petX, y: petY)
            }

            let dist = hypot(mouseLoc.x - petScreenPoint.x, mouseLoc.y - petScreenPoint.y)
            let isNear = dist <= 64.0

            if settings.isPetProximityHovered != isNear {
                settings.isPetProximityHovered = isNear
            }
        } else {
            if settings.isPetProximityHovered {
                settings.isPetProximityHovered = false
            }
        }
    }

    private func observeNotifications() {
        NotificationCenter.default.publisher(for: NSApplication.didChangeScreenParametersNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateFrame()
            }
            .store(in: &cancellables)

        settings.$barPosition
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateFrame()
            }
            .store(in: &cancellables)

        settings.$barWidth
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateFrame()
            }
            .store(in: &cancellables)

        settings.$hoverWidth
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateFrame()
            }
            .store(in: &cancellables)

        settings.$isBarVisible
            .receive(on: DispatchQueue.main)
            .sink { [weak self] visible in
                if visible {
                    self?.orderFrontRegardless()
                } else {
                    self?.orderOut(nil)
                }
            }
            .store(in: &cancellables)
    }
}

// MARK: - 화면 가장자리 전용 마우스 클릭 패스스루 및 네이티브 컨텍스트 메뉴 NSHostingView
private final class EdgePassthroughHostingView<Content: View>: NSHostingView<Content>, NSMenuItemValidation {
    private let settings: AppSettings

    init(rootView: Content, settings: AppSettings) {
        self.settings = settings
        super.init(rootView: rootView)
    }

    @MainActor required dynamic init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @MainActor required dynamic init(rootView: Content) {
        self.settings = .shared
        super.init(rootView: rootView)
    }

    // 바 내부 영역 판정 (윈도우 좌표계 기준, 최소 12px 감도 버퍼)
    private func isHitInBar(windowPoint: NSPoint) -> Bool {
        let thickness = max(settings.barWidth, settings.hoverWidth)
        let hitMargin: CGFloat = max(thickness, 12.0)

        switch settings.barPosition {
        case .left:
            return windowPoint.x >= 0 && windowPoint.x <= hitMargin
        case .right:
            return windowPoint.x >= (bounds.width - hitMargin) && windowPoint.x <= bounds.width
        case .bottom:
            return windowPoint.y >= 0 && windowPoint.y <= hitMargin
        }
    }

    // 물리 바 두께 이외 영역의 마우스 클릭을 하위 앱으로 관통
    override func hitTest(_ point: NSPoint) -> NSView? {
        if isHitInBar(windowPoint: point) {
            return self
        }
        return nil
    }

    // 메뉴 아이템 항상 활성화 유효성 검증
    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        return true
    }

    // 마우스 우클릭 시 네이티브 컨텍스트 메뉴 표시
    override func menu(for event: NSEvent) -> NSMenu? {
        guard isHitInBar(windowPoint: event.locationInWindow) else { return nil }

        let menu = NSMenu()
        menu.autoenablesItems = false

        let settingsItem = NSMenuItem(title: L10n.tr(.settings, lang: settings.language), action: #selector(openSettings(_:)), keyEquivalent: ",")
        settingsItem.target = self
        settingsItem.isEnabled = true
        menu.addItem(settingsItem)

        let refreshItem = NSMenuItem(title: L10n.tr(.refresh, lang: settings.language), action: #selector(refreshCalendars(_:)), keyEquivalent: "r")
        refreshItem.target = self
        refreshItem.isEnabled = true
        menu.addItem(refreshItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: L10n.tr(.quit, lang: settings.language), action: #selector(quitApp(_:)), keyEquivalent: "q")
        quitItem.target = self
        quitItem.isEnabled = true
        menu.addItem(quitItem)

        return menu
    }

    override func rightMouseDown(with event: NSEvent) {
        if let menu = self.menu(for: event) {
            NSMenu.popUpContextMenu(menu, with: event, for: self)
        } else {
            super.rightMouseDown(with: event)
        }
    }

    override func mouseDown(with event: NSEvent) {
        if event.clickCount == 2 {
            openSettings(nil)
        } else {
            super.mouseDown(with: event)
        }
    }

    @objc private func openSettings(_ sender: Any?) {
        (NSApp.delegate as? AppDelegate)?.openSettings()
    }

    @objc private func refreshCalendars(_ sender: Any?) {
        CalendarService.shared.loadCalendars()
        CalendarService.shared.fetchEvents(settings: settings)
    }

    @objc private func quitApp(_ sender: Any?) {
        NSApplication.shared.terminate(nil)
    }
}
