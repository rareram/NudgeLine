// 화면 가장자리 상주 플로팅 NSPanel 및 마우스 무간섭 패스스루 제어
import AppKit
import SwiftUI
import Combine

public final class OverlayPanel: NSPanel {
    private let targetScreen: NSScreen
    private let settings: AppSettings
    private var cancellables = Set<AnyCancellable>()
    private var mouseTrackingTimer: Timer?
    private var presentationCheckTimer: Timer?
    private var isOccludedByFullScreen: Bool = false

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
        self.collectionBehavior = settings.hideOnFullScreen ? [.canJoinAllSpaces, .stationary, .ignoresCycle] : [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
        self.sharingType = settings.hideOnScreenShare ? .none : .readOnly
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
        startPresentationTracking()
        scheduleBurstChecks()
    }

    deinit {
        cleanup()
    }

    // 패널 파기 시 리소스 및 타이머 명시적 정리
    public func cleanup() {
        mouseTrackingTimer?.invalidate()
        mouseTrackingTimer = nil
        presentationCheckTimer?.invalidate()
        presentationCheckTimer = nil
        cancellables.removeAll()
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
        // 전체화면/슬라이드쇼 은폐 중에는 100% 클릭 관통 강제 유지
        if isOccludedByFullScreen {
            if !self.ignoresMouseEvents {
                self.ignoresMouseEvents = true
            }
            return
        }

        let mouseLoc = NSEvent.mouseLocation
        if mouseLoc == lastMouseLoc { return }
        lastMouseLoc = mouseLoc
        let panelRect = self.frame

        // 1. 물리 타임라인 바 영역 진입 여부 판정 (설정된 바/호버 두께와 1:1 일치)
        let effectiveThickness = settings.expandOnHover ? max(settings.barWidth, settings.hoverWidth) : settings.barWidth
        let hitMargin: CGFloat = effectiveThickness
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

        settings.$hideOnScreenShare
            .receive(on: DispatchQueue.main)
            .sink { [weak self] hide in
                self?.sharingType = hide ? .none : .readOnly
            }
            .store(in: &cancellables)

        settings.$hideOnFullScreen
            .receive(on: DispatchQueue.main)
            .sink { [weak self] hide in
                self?.collectionBehavior = hide ? [.canJoinAllSpaces, .stationary, .ignoresCycle] : [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
                self?.scheduleBurstChecks()
            }
            .store(in: &cancellables)

        // 활성 앱 전환 및 스페이스 전환 시 즉시 버스트 재시도 검사 (애니메이션 완료 동기화)
        let wsCenter = NSWorkspace.shared.notificationCenter
        Publishers.Merge(
            wsCenter.publisher(for: NSWorkspace.didActivateApplicationNotification),
            wsCenter.publisher(for: NSWorkspace.activeSpaceDidChangeNotification)
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] _ in
            self?.scheduleBurstChecks()
        }
        .store(in: &cancellables)

        // 절전 및 화면 꺼짐 시 30Hz 마우스 및 프레젠테이션 감시 타이머 정지 (배터리 보존)
        Publishers.Merge(
            wsCenter.publisher(for: NSWorkspace.willSleepNotification),
            wsCenter.publisher(for: NSWorkspace.screensDidSleepNotification)
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] _ in
            self?.mouseTrackingTimer?.invalidate()
            self?.mouseTrackingTimer = nil
            self?.presentationCheckTimer?.invalidate()
            self?.presentationCheckTimer = nil
        }
        .store(in: &cancellables)

        // 깨어남 및 화면 켜짐 시 감시 타이머 재개
        Publishers.Merge(
            wsCenter.publisher(for: NSWorkspace.didWakeNotification),
            wsCenter.publisher(for: NSWorkspace.screensDidWakeNotification)
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] _ in
            self?.startMouseTracking()
            self?.startPresentationTracking()
            self?.scheduleBurstChecks()
        }
        .store(in: &cancellables)
    }

    // 스페이스 전환 애니메이션(300~400ms) 레이스 컨디션을 극복하는 버스트 재시도 검사
    private func scheduleBurstChecks() {
        self.checkFullScreenAndPresentation()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.10) { [weak self] in
            self?.checkFullScreenAndPresentation()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.30) { [weak self] in
            self?.checkFullScreenAndPresentation()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.50) { [weak self] in
            self?.checkFullScreenAndPresentation()
        }
    }

    // 저주파(1.5초) 프레젠테이션/보더리스 전체화면 창 감시 루프 (App Nap 및 저전력 보존)
    private func startPresentationTracking() {
        presentationCheckTimer?.invalidate()
        let timer = Timer(timeInterval: 1.5, repeats: true) { [weak self] _ in
            self?.checkFullScreenAndPresentation()
        }
        RunLoop.main.add(timer, forMode: .common)
        presentationCheckTimer = timer
    }

    // 듀얼 시그널 기반 몰입형 전체화면 및 프레젠테이션 실시간 감지
    private func checkFullScreenAndPresentation() {
        guard settings.hideOnFullScreen else {
            if self.isOccludedByFullScreen {
                self.isOccludedByFullScreen = false
            }
            if self.alphaValue != 1.0 {
                self.alphaValue = 1.0
            }
            return
        }

        let currentPid = ProcessInfo.processInfo.processIdentifier

        guard let windowList = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as? [[String: Any]] else {
            return
        }

        var onScreenCoveringApps = Set<String>()
        var hasOffscreenWindows = false
        var hasFullScreenLayer = false
        var maxCoveringHeight: CGFloat = 0.0

        for win in windowList {
            let owner = win[kCGWindowOwnerName as String] as? String ?? ""
            let pid = win[kCGWindowOwnerPID as String] as? pid_t ?? 0
            let layer = win[kCGWindowLayer as String] as? Int ?? 0
            guard pid != currentPid else { continue }

            guard let boundsDict = win[kCGWindowBounds as String] as? [String: Any],
                  let winBounds = CGRect(dictionaryRepresentation: boundsDict as CFDictionary) else { continue }

            // 전체화면 전용 특수 레이어 감지 (크롬 툴바: 26, 전체화면 종료 배너: 999)
            if (layer == 26 || layer == 999) && owner != "Window Server" {
                hasFullScreenLayer = true
            }

            if layer == 0 {
                // 다른 스페이스로 밀려난 창(음수 X 좌표) 감지
                if winBounds.minX <= -100.0 {
                    hasOffscreenWindows = true
                }

                // 현재 화면 안(X >= 0)에 떠 있는 화면 크기 창 감지
                if winBounds.minX >= -10.0 && winBounds.minX < targetScreen.frame.width {
                    if winBounds.width >= targetScreen.frame.width - 20.0 &&
                       winBounds.height >= targetScreen.visibleFrame.height - 20.0 {
                        onScreenCoveringApps.insert(owner)
                        if winBounds.height > maxCoveringHeight {
                            maxCoveringHeight = winBounds.height
                        }
                    }
                }
            }
        }

        // [실측 기반 전체화면 및 프레젠테이션 확정 조건]
        // 1. 크롬 / IINA / Keynote (네이티브 전체화면 스페이스: 단 1개 앱만 화면을 독점하고 다른 앱은 스페이스 밖으로 밀려남)
        let isNativeFullScreenSpace = (onScreenCoveringApps.count == 1) && (hasOffscreenWindows || hasFullScreenLayer)

        // 2. MS 파워포인트 슬라이드쇼 (동일 스페이스 화면 100% 덮음: 뒤에 다른 창이 있어도 화면 전체를 100% 덮은 발표 창 존재)
        let isSameSpacePresentation = (maxCoveringHeight >= targetScreen.frame.height - 5.0)

        let isOccluded = isNativeFullScreenSpace || isSameSpacePresentation

        self.isOccludedByFullScreen = isOccluded

        if isOccluded {
            if self.alphaValue != 0.0 {
                self.alphaValue = 0.0
                self.ignoresMouseEvents = true
                PopoverPanel.shared.hide(delayed: false)
            }
        } else {
            if self.alphaValue != 1.0 {
                self.alphaValue = 1.0
            }
        }
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

    // 바 내부 영역 판정 (윈도우 좌표계 기준, 설정된 두께와 1:1 일치)
    private func isHitInBar(windowPoint: NSPoint) -> Bool {
        let thickness = settings.expandOnHover ? max(settings.barWidth, settings.hoverWidth) : settings.barWidth
        let hitMargin: CGFloat = thickness

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

        let refreshItem = NSMenuItem(title: L10n.tr(.refresh, lang: settings.language), action: #selector(refreshCalendars(_:)), keyEquivalent: "r")
        refreshItem.target = self
        refreshItem.isEnabled = true
        menu.addItem(refreshItem)

        let settingsItem = NSMenuItem(title: L10n.tr(.settings, lang: settings.language), action: #selector(openSettings(_:)), keyEquivalent: ",")
        settingsItem.target = self
        settingsItem.isEnabled = true
        menu.addItem(settingsItem)

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
