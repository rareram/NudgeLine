// 팝오버 플로팅 패널 관리자 및 FirstMouse 호버 브릿지 제어
import AppKit
import SwiftUI
import Combine

// MARK: - 1. FirstMouse 호버 브릿지 뷰 (FirstMouseHostingView)
public final class FirstMouseHostingView<Content: View>: NSHostingView<Content> {
    public override var acceptsFirstResponder: Bool { true }
    private var trackingArea: NSTrackingArea?

    public override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true
    }

    public override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let existing = trackingArea {
            removeTrackingArea(existing)
        }
        let options: NSTrackingArea.Options = [.mouseEnteredAndExited, .activeAlways, .inVisibleRect]
        let newArea = NSTrackingArea(rect: bounds, options: options, owner: self, userInfo: nil)
        addTrackingArea(newArea)
        self.trackingArea = newArea
    }

    public override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        PopoverPanel.shared.setMouseInside(true)
    }

    public override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        PopoverPanel.shared.setMouseInside(false)
    }
}

// MARK: - 2. 팝오버 단일 패널 윈도우 인스턴스 (PopoverPanel)
public final class PopoverPanel: NSPanel {
    public static let shared = PopoverPanel()

    private var hostingView: FirstMouseHostingView<AnyView>?
    private var hideTimer: Timer?
    private var currentClusterId: String? = nil
    // private var isMouseInside: Bool = false
    private var hasEnteredPopover: Bool = false
    private var isDetailMode: Bool = false
    private var showGeneration: Int = 0
    private var cancellables = Set<AnyCancellable>()

    // 빈 영역 종일 일정 툴팁 -> 상세 카드 확장용 상태
    private var pendingAllDayEvents: [CalendarEvent] = []
    private var pendingTooltipContext: (cursorOffset: CGFloat, isHorizontal: Bool, barPosition: BarPosition, settings: AppSettings)? = nil

    private init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 250, height: 160),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        self.level = .floating + 1
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = false
        self.ignoresMouseEvents = false
        self.acceptsMouseMovedEvents = true

        // 화면 공유 및 전체 화면 은폐 설정 실시간 동기화
        AppSettings.shared.$hideOnScreenShare
            .receive(on: DispatchQueue.main)
            .sink { [weak self] hide in
                self?.sharingType = hide ? .none : .readOnly
            }
            .store(in: &cancellables)

        AppSettings.shared.$hideOnFullScreen
            .receive(on: DispatchQueue.main)
            .sink { [weak self] hide in
                self?.collectionBehavior = hide ? [.canJoinAllSpaces, .transient] : [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
            }
            .store(in: &cancellables)

        AppSettings.shared.$eventCardTheme
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updatePanelAppearance(settings: AppSettings.shared)
            }
            .store(in: &cancellables)

        updatePanelAppearance(settings: AppSettings.shared)
    }

    private func updatePanelAppearance(settings: AppSettings) {
        let targetAppearance: NSAppearance?
        switch settings.eventCardTheme {
        case .adaptive:
            targetAppearance = nil
        case .dark:
            targetAppearance = NSAppearance(named: .darkAqua)
        case .light:
            targetAppearance = NSAppearance(named: .aqua)
        }
        self.appearance = targetAppearance
        self.hostingView?.appearance = targetAppearance
    }

    public func setMouseInside(_ inside: Bool) {
        // self.isMouseInside = inside
        if inside {
            self.hasEnteredPopover = true
            hideTimer?.invalidate()
            hideTimer = nil

            // [종일 일정 툴팁 -> 상세 액션 카드 자동 확장]
            if !pendingAllDayEvents.isEmpty, let context = pendingTooltipContext {
                expandToAllDayCard(events: pendingAllDayEvents, context: context)
                self.pendingAllDayEvents = []
                self.pendingTooltipContext = nil
            }
        } else {
            hide(delayed: true)
        }
    }

    // 마우스 커서가 현재 위치한 디스플레이 화면 반환 (다중 모니터 대응)
    private func currentTargetScreen() -> NSScreen? {
        let mouseLoc = NSEvent.mouseLocation
        return NSScreen.screens.first(where: { $0.frame.contains(mouseLoc) }) ?? NSScreen.main ?? NSScreen.screens.first
    }
}

// MARK: - 3. 일정 호버 팝오버 표시 및 좌표 애니메이션
extension PopoverPanel {
    public func show(
        events: [CalendarEvent],
        allDayEvents: [CalendarEvent] = [],
        clusterId: String,
        blockOffset: CGFloat,
        blockLength: CGFloat,
        isHorizontal: Bool,
        barPosition: BarPosition,
        settings: AppSettings = .shared
    ) {
        showGeneration += 1
        hasEnteredPopover = false
        hideTimer?.invalidate()
        hideTimer = nil
        self.pendingAllDayEvents = []
        self.pendingTooltipContext = nil

        guard let screen = currentTargetScreen(), !events.isEmpty else { return }
        updatePanelAppearance(settings: settings)

        let renderer = settings.eventHoverStyle.renderer()
        self.isDetailMode = renderer.allowsTransitBridge
        let visibleFrame = screen.visibleFrame
        let fullFrame = screen.frame
        let thickness = max(settings.barWidth, settings.hoverWidth)

        let targetDimensions = renderer.targetSize(
            events: events,
            allDayEvents: allDayEvents,
            isHorizontal: isHorizontal
        )
        let targetWidth = targetDimensions.width
        let targetHeight = targetDimensions.height

        let anyView = renderer.makeView(
            events: events,
            allDayEvents: allDayEvents,
            settings: settings
        )

        if let hosting = hostingView {
            hosting.rootView = anyView
        } else {
            let hosting = FirstMouseHostingView(rootView: anyView)
            hosting.appearance = self.appearance
            self.contentView = hosting
            self.hostingView = hosting
        }

        var finalX: CGFloat
        var finalY: CGFloat
        var startX: CGFloat
        var startY: CGFloat

        if isHorizontal {
            let idealFinalX = visibleFrame.minX + blockOffset + (blockLength / 2) - (targetWidth / 2)
            finalX = max(visibleFrame.minX + 8, min(visibleFrame.maxX - targetWidth - 8, idealFinalX))
            finalY = visibleFrame.minY + thickness + 6
            startX = finalX
            startY = finalY - 8
        } else {
            let idealFinalY = visibleFrame.maxY - blockOffset - (blockLength / 2) - (targetHeight / 2)
            finalY = max(visibleFrame.minY + 8, min(visibleFrame.maxY - targetHeight - 8, idealFinalY))

            switch barPosition {
            case .left:
                finalX = fullFrame.minX + thickness + 6
                startX = finalX - 8
                startY = finalY
            case .right:
                finalX = fullFrame.maxX - thickness - targetWidth - 6
                startX = finalX + 8
                startY = finalY
            case .bottom:
                let idealFinalX = visibleFrame.minX + blockOffset + (blockLength / 2) - (targetWidth / 2)
                finalX = max(visibleFrame.minX + 8, min(visibleFrame.maxX - targetWidth - 8, idealFinalX))
                finalY = visibleFrame.minY + thickness + 6
                startX = finalX
                startY = finalY - 8
            }
        }

        let isNewCluster = currentClusterId != clusterId || !self.isVisible
        currentClusterId = clusterId

        let finalFrame = NSRect(x: finalX, y: finalY, width: targetWidth, height: targetHeight)
        let startFrame = NSRect(x: startX, y: startY, width: targetWidth, height: targetHeight)

        if !self.isVisible {
            self.setFrame(startFrame, display: true, animate: false)
            self.alphaValue = 0.0
            self.orderFrontRegardless()
            NSAnimationContext.runAnimationGroup { ctx in
                ctx.duration = 0.15
                ctx.timingFunction = CAMediaTimingFunction(name: .easeOut)
                self.animator().setFrame(finalFrame, display: true)
                self.animator().alphaValue = 1.0
            }
        } else if isNewCluster {
            NSAnimationContext.runAnimationGroup { ctx in
                ctx.duration = 0.12
                ctx.timingFunction = CAMediaTimingFunction(name: .easeOut)
                self.animator().setFrame(finalFrame, display: true)
                self.animator().alphaValue = 1.0
            }
        } else {
            self.setFrame(finalFrame, display: true, animate: false)
        }
    }
}

// MARK: - 4. 미니 툴팁 및 안내 팝오버 표시
extension PopoverPanel {
    private func calculateTooltipFrame(
        offset: CGFloat,
        targetWidth: CGFloat,
        targetHeight: CGFloat,
        isHorizontal: Bool,
        barPosition: BarPosition,
        settings: AppSettings,
        screen: NSScreen
    ) -> NSRect {
        let visibleFrame = screen.visibleFrame
        let fullFrame = screen.frame
        let thickness = max(settings.barWidth, settings.hoverWidth)

        var finalX: CGFloat
        var finalY: CGFloat

        if isHorizontal {
            finalX = visibleFrame.minX + offset - (targetWidth / 2)
            finalY = visibleFrame.minY + thickness + 4
            finalX = max(visibleFrame.minX + 4, min(visibleFrame.maxX - targetWidth - 4, finalX))
        } else {
            finalY = visibleFrame.maxY - offset - (targetHeight / 2)
            finalY = max(visibleFrame.minY + 4, min(visibleFrame.maxY - targetHeight - 4, finalY))

            switch barPosition {
            case .left:
                finalX = fullFrame.minX + thickness + 4
            case .right:
                finalX = fullFrame.maxX - thickness - targetWidth - 4
            case .bottom:
                finalX = visibleFrame.minX + offset - (targetWidth / 2)
            }
        }
        return NSRect(x: finalX, y: finalY, width: targetWidth, height: targetHeight)
    }

    public func showTimeTooltip(
        currentTime: Date,
        timeOffset: CGFloat,
        isHorizontal: Bool,
        barPosition: BarPosition,
        settings: AppSettings = .shared
    ) {
        guard let screen = currentTargetScreen() else { return }

        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "M.d (E) HH:mm"
        let timeString = timeFormatter.string(from: currentTime)

        let targetWidth: CGFloat
        let targetHeight: CGFloat
        if settings.isPetSnoozed {
            let fontRow1 = NSFont.systemFont(ofSize: 10.5, weight: .semibold)
            let row1Width = (timeString as NSString).size(withAttributes: [.font: fontRow1]).width + 9.0

            let subText = L10n.tr(.petSnoozedTooltip(settings.remainingSnoozeMinutes), lang: settings.language)
            let fontRow2 = NSFont.systemFont(ofSize: 9.0, weight: .medium)
            let row2Width = (subText as NSString).size(withAttributes: [.font: fontRow2]).width

            let contentWidth = max(row1Width, row2Width)
            targetWidth = ceil(contentWidth + 30.0)
            targetHeight = 38.0
        } else {
            let font = NSFont.systemFont(ofSize: 10.0, weight: .semibold)
            let textWidth = (timeString as NSString).size(withAttributes: [.font: font]).width
            targetWidth = ceil(textWidth + 28.0)
            targetHeight = 24.0
        }

        let finalFrame = calculateTooltipFrame(
            offset: timeOffset,
            targetWidth: targetWidth,
            targetHeight: targetHeight,
            isHorizontal: isHorizontal,
            barPosition: barPosition,
            settings: settings,
            screen: screen
        )

        presentTooltip(
            content: AnyView(CurrentTimeTooltipView(
                currentTime: currentTime,
                timeOffset: timeOffset,
                isHorizontal: isHorizontal,
                barPosition: barPosition,
                settings: settings
            )),
            frame: finalFrame,
            clusterId: "__CURRENT_TIME_TOOLTIP__",
            isDetailMode: false,
            settings: settings
        )
    }

    public func showReminderTooltip(
        reminder: ReminderItem,
        offset: CGFloat,
        isHorizontal: Bool,
        barPosition: BarPosition,
        settings: AppSettings = .shared
    ) {
        guard let screen = currentTargetScreen() else { return }

        let font = NSFont.systemFont(ofSize: 10, weight: .medium)
        let sampleText = "00:00 \(reminder.title) \(reminder.listTitle)"
        let textWidth = (sampleText as NSString).size(withAttributes: [.font: font]).width
        let targetWidth = min(360.0, max(130.0, ceil(textWidth + 36.0)))
        let targetHeight: CGFloat = 24.0

        let finalFrame = calculateTooltipFrame(
            offset: offset,
            targetWidth: targetWidth,
            targetHeight: targetHeight,
            isHorizontal: isHorizontal,
            barPosition: barPosition,
            settings: settings,
            screen: screen
        )

        let clusterId = "__REMINDER_TOOLTIP_\(reminder.id)__"

        presentTooltip(
            content: AnyView(ReminderTooltipView(reminder: reminder, settings: settings)),
            frame: finalFrame,
            clusterId: clusterId,
            isDetailMode: false,
            settings: settings
        )
    }

    public func showEmptyScheduleTooltip(
        cursorOffset: CGFloat,
        allDayEvents: [CalendarEvent] = [],
        outOfRangeEvents: [CalendarEvent] = [],
        hasTimedEventsInRange: Bool = false,
        hasConnectedCalendars: Bool = true,
        isHorizontal: Bool,
        barPosition: BarPosition,
        settings: AppSettings = .shared
    ) {
        guard let screen = currentTargetScreen() else { return }

        // 텍스트 길이에 맞춰 툴팁 너비를 자연스럽게 조절합니다.
        let text = EmptyScheduleTooltipView.tooltipText(
            for: allDayEvents,
            outOfRangeEvents: outOfRangeEvents,
            hasTimedEventsInRange: hasTimedEventsInRange,
            hasConnectedCalendars: hasConnectedCalendars,
            settings: settings
        )
        let font = NSFont.systemFont(ofSize: 10, weight: .medium)
        let textWidth = (text as NSString).size(withAttributes: [.font: font]).width
        let targetWidth = min(340.0, max(80.0, ceil(textWidth + 30.0)))

        let finalFrame = calculateTooltipFrame(
            offset: cursorOffset,
            targetWidth: targetWidth,
            targetHeight: 24.0,
            isHorizontal: isHorizontal,
            barPosition: barPosition,
            settings: settings,
            screen: screen
        )

        let clusterId = "__SCHEDULE_STATUS_TOOLTIP__" +
            allDayEvents.map(\.id).sorted().joined(separator: "_") +
            outOfRangeEvents.map(\.id).sorted().joined(separator: "_") +
            "_\(hasTimedEventsInRange)_\(hasConnectedCalendars)_\(settings.eventHoverStyle.rawValue)"

        // 당일 종일 일정이 있는 경우 마우스 호버 브릿지 활성화 및 확장 컨텍스트 보관
        if !allDayEvents.isEmpty {
            self.pendingAllDayEvents = allDayEvents
            self.pendingTooltipContext = (cursorOffset, isHorizontal, barPosition, settings)
        } else {
            self.pendingAllDayEvents = []
            self.pendingTooltipContext = nil
        }

        presentTooltip(
            content: AnyView(EmptyScheduleTooltipView(
                allDayEvents: allDayEvents,
                outOfRangeEvents: outOfRangeEvents,
                hasTimedEventsInRange: hasTimedEventsInRange,
                hasConnectedCalendars: hasConnectedCalendars,
                settings: settings
            )),
            frame: finalFrame,
            clusterId: clusterId,
            isDetailMode: !allDayEvents.isEmpty, // 종일 일정이 있을 때는 마우스가 툴팁으로 건너올 수 있도록 브릿지 활성화
            settings: settings
        )
    }

    // MARK: - 종일 일정 미니 툴팁 -> 상세 액션 카드 자동 확장
    // [원인/배경: 시간 일정과의 구분을 위해 24px 미니 툴팁으로 시작하되, 마우스가 툴팁에 올라가면 전체 상세 정보(링크/메모)를 확인 가능해야 함 -> 해결 방법: mouseEntered 시점에 종일 일정을 상세 카드로 교체하고 부드러운 스프링 프레임 확장 애니메이션 적용 -> 기대 효과: 시간 블록과 빈 공간의 리듬감 보존 및 종일 일정 정보 손실 없는 완벽한 UX 달성]
    private func expandToAllDayCard(
        events: [CalendarEvent],
        context: (cursorOffset: CGFloat, isHorizontal: Bool, barPosition: BarPosition, settings: AppSettings)
    ) {
        guard let screen = currentTargetScreen(), !events.isEmpty else { return }
        self.currentClusterId = "__ALL_DAY_CARD_EXPANDED__"
        updatePanelAppearance(settings: context.settings)

        let renderer = context.settings.eventHoverStyle.renderer()
        self.isDetailMode = true

        let targetDimensions = renderer.targetSize(
            events: events,
            allDayEvents: [],
            isHorizontal: context.isHorizontal
        )
        let targetWidth = targetDimensions.width
        let targetHeight = targetDimensions.height

        let anyView = renderer.makeView(
            events: events,
            allDayEvents: [],
            settings: context.settings
        )

        if let hosting = hostingView {
            hosting.rootView = anyView
        } else {
            let hosting = FirstMouseHostingView(rootView: anyView)
            hosting.appearance = self.appearance
            self.contentView = hosting
            self.hostingView = hosting
        }

        let visibleFrame = screen.visibleFrame
        let fullFrame = screen.frame
        let thickness = max(context.settings.barWidth, context.settings.hoverWidth)

        var finalX: CGFloat
        var finalY: CGFloat

        if context.isHorizontal {
            let idealFinalX = visibleFrame.minX + context.cursorOffset - (targetWidth / 2)
            finalX = max(visibleFrame.minX + 8, min(visibleFrame.maxX - targetWidth - 8, idealFinalX))
            finalY = visibleFrame.minY + thickness + 6
        } else {
            let idealFinalY = visibleFrame.maxY - context.cursorOffset - (targetHeight / 2)
            finalY = max(visibleFrame.minY + 8, min(visibleFrame.maxY - targetHeight - 8, idealFinalY))

            switch context.barPosition {
            case .left:
                finalX = fullFrame.minX + thickness + 6
            case .right:
                finalX = fullFrame.maxX - thickness - targetWidth - 6
            case .bottom:
                finalX = visibleFrame.minX + context.cursorOffset - (targetWidth / 2)
                finalY = visibleFrame.minY + thickness + 6
            }
        }

        let expandedFrame = NSRect(x: finalX, y: finalY, width: targetWidth, height: targetHeight)

        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.16
            ctx.timingFunction = CAMediaTimingFunction(name: .easeOut)
            self.animator().setFrame(expandedFrame, display: true)
        }
    }

    public func showPermissionNotice(
        cursorOffset: CGFloat,
        isHorizontal: Bool,
        barPosition: BarPosition,
        settings: AppSettings = .shared
    ) {
        guard let screen = currentTargetScreen() else { return }

        let targetWidth: CGFloat = settings.language.isKorean ? 260.0 : 360.0
        let finalFrame = calculateTooltipFrame(
            offset: cursorOffset,
            targetWidth: targetWidth,
            targetHeight: 28.0,
            isHorizontal: isHorizontal,
            barPosition: barPosition,
            settings: settings,
            screen: screen
        )

        presentTooltip(
            content: AnyView(PermissionNoticeTooltipView(settings: settings)),
            frame: finalFrame,
            clusterId: "__PERMISSION_NOTICE__",
            isDetailMode: true, // 시스템 설정 열기 버튼을 클릭할 수 있도록 마우스 브릿지를 유지합니다.
            settings: settings
        )
    }

    // 여러 소형 툴팁(현재 시각, 빈 일정 안내, 권한 알림 등)을 공통 페이드 애니메이션으로 표시합니다.
    private func presentTooltip(
        content: AnyView,
        frame: NSRect,
        clusterId: String,
        isDetailMode: Bool,
        settings: AppSettings = .shared
    ) {
        showGeneration += 1
        hasEnteredPopover = false
        hideTimer?.invalidate()
        hideTimer = nil
        self.isDetailMode = isDetailMode
        updatePanelAppearance(settings: settings)

        if let hosting = hostingView {
            hosting.rootView = content
        } else {
            let hosting = FirstMouseHostingView(rootView: content)
            hosting.appearance = self.appearance
            self.contentView = hosting
            self.hostingView = hosting
        }

        let isNew = !self.isVisible || currentClusterId != clusterId || self.frame.size != frame.size
        currentClusterId = clusterId

        if !self.isVisible {
            self.setFrame(frame, display: true, animate: false)
            self.alphaValue = 0.0
            self.orderFrontRegardless()
            NSAnimationContext.runAnimationGroup { ctx in
                ctx.duration = 0.12
                self.animator().alphaValue = 1.0
            }
        } else if isNew {
            NSAnimationContext.runAnimationGroup { ctx in
                ctx.duration = 0.1
                self.animator().setFrame(frame, display: true)
                self.animator().alphaValue = 1.0
            }
        }
    }
}

// MARK: - 5. 팝오버 닫기 및 애니메이션 타이머
extension PopoverPanel {
    // 팝오버 숨김 타이머 (대각선 진입 시 0.20초 보호, 팝오버 이탈 시 0.04초 즉시 닫기)
    public func hide(delayed: Bool = false) {
        hideTimer?.invalidate()
        if delayed {
            let delayTime: TimeInterval = hasEnteredPopover ? 0.04 : (isDetailMode ? 0.20 : 0.04)
            let timer = Timer(timeInterval: delayTime, repeats: false) { [weak self] _ in
                guard let self = self else { return }
                // 타이머 만료 시 실제 OS 마우스 절대 좌표로 물리적 검증 (박제 방지)
                if self.frame.contains(NSEvent.mouseLocation) {
                    return
                }
                // self.isMouseInside = false
                self.performHide()
            }
            RunLoop.main.add(timer, forMode: .common)
            hideTimer = timer
        } else {
            performHide()
        }
    }

    // 팝오버 페이드아웃 및 닫기 수행
    private func performHide() {
        guard self.isVisible else { return }
        let hideGen = showGeneration
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.10
            self.animator().alphaValue = 0.0
        }, completionHandler: { [weak self] in
            guard let self = self else { return }
            if self.showGeneration == hideGen {
                self.orderOut(nil)
                self.currentClusterId = nil
                // self.isMouseInside = false
                self.hasEnteredPopover = false
            }
        })
    }
}

// MARK: - 5-3. 수면 잔물결 액체 셰이프 (다중 조화파 합성 유체 파동)
private struct LiquidWaveShape: Shape {
    var fillWidth: CGFloat
    var time: Double

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard fillWidth > 0 else { return path }

        let clampedWidth = min(rect.width, fillWidth)
        let phase1 = time * 1.7
        let phase2 = time * 2.3
        let phase3 = time * 0.9

        func waveOffset(at y: CGFloat) -> CGFloat {
            let w1 = sin((y / 28.0) * 2.0 * .pi + phase1) * 0.9
            let w2 = sin((y / 18.0) * 2.0 * .pi - phase2) * 0.4
            let w3 = cos((y / 40.0) * 2.0 * .pi + phase3) * 0.3
            return w1 + w2 + w3
        }

        path.move(to: CGPoint(x: 0, y: 0))
        let startX = max(0, min(rect.width, clampedWidth + waveOffset(at: 0)))
        path.addLine(to: CGPoint(x: startX, y: 0))

        let step: CGFloat = 1.5
        var y: CGFloat = step
        while y <= rect.height {
            let currentX = max(0, min(rect.width, clampedWidth + waveOffset(at: y)))
            path.addLine(to: CGPoint(x: currentX, y: y))
            y += step
        }

        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()
        return path
    }
}

// MARK: - 5-4. 수면 잔물결 하이라이트 셰이프 (LiquidWaveCrestShape)
private struct LiquidWaveCrestShape: Shape {
    var fillWidth: CGFloat
    var time: Double

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard fillWidth > 2 else { return path }

        let clampedWidth = min(rect.width, fillWidth)
        let phase1 = time * 1.7
        let phase2 = time * 2.3
        let phase3 = time * 0.9

        func waveOffset(at y: CGFloat) -> CGFloat {
            let w1 = sin((y / 28.0) * 2.0 * .pi + phase1) * 0.9
            let w2 = sin((y / 18.0) * 2.0 * .pi - phase2) * 0.4
            let w3 = cos((y / 40.0) * 2.0 * .pi + phase3) * 0.3
            return w1 + w2 + w3
        }

        let step: CGFloat = 1.5
        var y: CGFloat = 0
        var isFirst = true

        while y <= rect.height {
            let currentX = max(0, min(rect.width, clampedWidth + waveOffset(at: y)))
            if isFirst {
                path.move(to: CGPoint(x: currentX, y: y))
                isFirst = false
            } else {
                path.addLine(to: CGPoint(x: currentX, y: y))
            }
            y += step
        }
        return path
    }
}

// MARK: - 6. 현재 시각 미니 툴팁 뷰 (CurrentTimeTooltipView)
private struct CurrentTimeTooltipView: View {
    let currentTime: Date
    var timeOffset: CGFloat = 0
    var isHorizontal: Bool = false
    var barPosition: BarPosition = .left
    @ObservedObject var settings: AppSettings

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "M.d (E) HH:mm"
        return f
    }()

    @Environment(\.colorScheme) private var colorScheme
    private var isDarkTheme: Bool {
        settings.eventCardTheme.isDark(for: colorScheme)
    }

    private var indicatorColor: Color {
        settings.isPetSnoozed
            ? Color(red: 0.35, green: 0.55, blue: 0.95)
            : settings.effectiveCurrentTimeColor()
    }

    var body: some View {
        ZStack {
            // 1. 원통형 물 채움 (Liquid Wave Fill) 배경 게이지
            if settings.isPetSnoozed {
                TimelineView(.animation) { timeline in
                    let time = timeline.date.timeIntervalSinceReferenceDate

                    GeometryReader { geo in
                        let fillWidth = geo.size.width * CGFloat(settings.remainingSnoozeRatio)
                        ZStack(alignment: .leading) {
                            // 물 본체 웨이브 (다중 조화파 합성)
                            LiquidWaveShape(fillWidth: fillWidth, time: time)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 0.35, green: 0.55, blue: 0.95).opacity(isDarkTheme ? 0.38 : 0.28),
                                            Color(red: 0.35, green: 0.55, blue: 0.95).opacity(isDarkTheme ? 0.22 : 0.14)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )

                            // 수면 잔물결 하이라이트
                            if fillWidth > 2 {
                                LiquidWaveCrestShape(fillWidth: fillWidth, time: time)
                                    .stroke(
                                        LinearGradient(
                                            colors: [
                                                Color.white.opacity(isDarkTheme ? 0.70 : 0.85),
                                                Color(red: 0.35, green: 0.55, blue: 0.95).opacity(0.90)
                                            ],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        ),
                                        lineWidth: 1.1
                                    )
                            }
                        }
                    }
                    .clipShape(Capsule())
                }
            }

            // 2. 텍스트 콘텐츠 (스누즈 여부에 따라 1행 또는 2행 구성)
            if settings.isPetSnoozed {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(indicatorColor)
                            .frame(width: 5, height: 5)
                            .shadow(color: indicatorColor.opacity(0.6), radius: 2)

                        Text(Self.timeFormatter.string(from: currentTime))
                            .font(.system(size: 10.5, weight: .semibold, design: .rounded))
                            .foregroundStyle(isDarkTheme ? Color.white : Color.black.opacity(0.9))
                            .lineLimit(1)
                    }

                    Text(L10n.tr(.petSnoozedTooltip(settings.remainingSnoozeMinutes), lang: settings.language))
                        .font(.system(size: 9.0, weight: .medium, design: .rounded))
                        .foregroundStyle(isDarkTheme ? Color.white.opacity(0.72) : Color.black.opacity(0.62))
                        .lineLimit(1)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            } else {
                HStack(spacing: 3.5) {
                    Circle()
                        .fill(indicatorColor)
                        .frame(width: 5, height: 5)
                        .shadow(color: indicatorColor.opacity(0.6), radius: 2)

                    Text(Self.timeFormatter.string(from: currentTime))
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(isDarkTheme ? Color.white : Color.black.opacity(0.9))
                        .lineLimit(1)
                }
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(
            VisualEffectBlur(
                material: .popover,
                blendingMode: .behindWindow,
                state: .active
            )
            .clipShape(Capsule())
        )
        .background(
            Capsule()
                .fill(isDarkTheme ? Color.black.opacity(0.85) : Color.white.opacity(0.75))
        )
        .overlay(
            Capsule()
                .stroke(
                    settings.isPetSnoozed
                        ? AnyShapeStyle(Color(red: 0.35, green: 0.55, blue: 0.95).opacity(isDarkTheme ? 0.45 : 0.35))
                        : AnyShapeStyle(
                            LinearGradient(
                                colors: isDarkTheme ? [
                                    Color.white.opacity(0.35),
                                    Color.white.opacity(0.10)
                                ] : [
                                    Color.black.opacity(0.18),
                                    Color.black.opacity(0.08)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        ),
                    lineWidth: 0.8
                )
        )
        .shadow(color: Color.black.opacity(isDarkTheme ? 0.25 : 0.15), radius: 6, x: 0, y: 3)
        .contentShape(Capsule())
        .onTapGesture {
            settings.togglePetSnooze()
            PopoverPanel.shared.showTimeTooltip(
                currentTime: currentTime,
                timeOffset: timeOffset,
                isHorizontal: isHorizontal,
                barPosition: barPosition,
                settings: settings
            )
        }
    }
}

// MARK: - 6-1. 미리알림 미니 툴팁 뷰 (ReminderTooltipView)
private struct ReminderTooltipView: View {
    let reminder: ReminderItem
    let settings: AppSettings

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }()

    @Environment(\.colorScheme) private var colorScheme
    private var isDarkTheme: Bool {
        settings.eventCardTheme.isDark(for: colorScheme)
    }

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: settings.reminderMarkerStyle.symbolName)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(reminder.color)

            Text(Self.timeFormatter.string(from: reminder.dueDate))
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(reminder.color)

            Text(reminder.title)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(isDarkTheme ? Color.white : Color.black.opacity(0.9))
                .lineLimit(1)

            if !reminder.listTitle.isEmpty {
                Text("· \(reminder.listTitle)")
                    .font(.system(size: 9, weight: .regular))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            VisualEffectBlur(
                material: .popover,
                blendingMode: .behindWindow,
                state: .active
            )
            .clipShape(Capsule())
        )
        .background(
            Capsule()
                .fill(isDarkTheme ? Color.black.opacity(0.85) : Color.white.opacity(0.75))
        )
        .overlay(
            Capsule()
                .stroke(
                    LinearGradient(
                        colors: isDarkTheme ? [
                            Color.white.opacity(0.35),
                            Color.white.opacity(0.10)
                        ] : [
                            Color.black.opacity(0.18),
                            Color.black.opacity(0.08)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.8
                )
        )
        .shadow(color: Color.black.opacity(isDarkTheme ? 0.25 : 0.15), radius: 6, x: 0, y: 3)
    }
}

// MARK: - 7. 빈 일정 및 종일 일정 안내 툴팁 뷰 (EmptyScheduleTooltipView)
private struct EmptyScheduleTooltipView: View {
    let allDayEvents: [CalendarEvent]
    let outOfRangeEvents: [CalendarEvent]
    let hasTimedEventsInRange: Bool
    let hasConnectedCalendars: Bool
    let settings: AppSettings

    @Environment(\.colorScheme) private var colorScheme
    private var isDarkTheme: Bool {
        settings.eventCardTheme.isDark(for: colorScheme)
    }

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }()

    static func tooltipText(
        for allDayEvents: [CalendarEvent],
        outOfRangeEvents: [CalendarEvent] = [],
        hasTimedEventsInRange: Bool = false,
        hasConnectedCalendars: Bool = true,
        settings: AppSettings
    ) -> String {
        let isCard = (settings.eventHoverStyle == .card)

        // 1. 종일 일정과 범위 외 일정이 모두 있는 경우
        if !allDayEvents.isEmpty && !outOfRangeEvents.isEmpty {
            let allDayTitle = allDayEvents[0].title(lang: settings.language)
            let firstOut = outOfRangeEvents[0]
            let timeStr = timeFormatter.string(from: firstOut.startDate)
            if isCard {
                return L10n.tr(.allDayWithOutOfRangeCard(allDayTitle, outOfRangeEvents.count, timeStr), lang: settings.language)
            } else {
                return L10n.tr(.allDayWithOutOfRangeSimple(allDayTitle, outOfRangeEvents.count), lang: settings.language)
            }
        }

        // 2. 종일 일정만 있는 경우
        if !allDayEvents.isEmpty {
            let title = allDayEvents[0].title(lang: settings.language)
            let otherCount = allDayEvents.count - 1

            if hasTimedEventsInRange {
                // 바에 이미 시간 블록들이 있는 빈 공간 호버 시에는 순수 종일 일정 제목만 표출
                return otherCount == 0
                    ? L10n.tr(.allDayNotice(title), lang: settings.language)
                    : L10n.tr(.allDayNoticeWithCount(title, otherCount), lang: settings.language)
            } else {
                // 바에 시간 블록이 전혀 없을 때 (카드 스타일 정보 밀도 분기 적용)
                if isCard {
                    return otherCount == 0
                        ? L10n.tr(.noTimedEventsWithAllDayCard(title), lang: settings.language)
                        : L10n.tr(.noTimedEventsWithAllDayCountCard(title, otherCount), lang: settings.language)
                } else {
                    return otherCount == 0
                        ? L10n.tr(.allDayNotice(title), lang: settings.language)
                        : L10n.tr(.allDayNoticeWithCount(title, otherCount), lang: settings.language)
                }
            }
        }

        // 3. 표시 범위 밖 시간 일정만 있는 경우 (바가 비어있는 상태)
        if !outOfRangeEvents.isEmpty {
            let firstOut = outOfRangeEvents[0]
            let timeStr = timeFormatter.string(from: firstOut.startDate)
            let title = firstOut.title(lang: settings.language)
            let count = outOfRangeEvents.count
            if isCard {
                return count == 1
                    ? L10n.tr(.outOfRangeSingleCard(timeStr, title), lang: settings.language)
                    : L10n.tr(.outOfRangeMultipleCard(count, timeStr, title), lang: settings.language)
            } else {
                return L10n.tr(.outOfRangeSimple(count, timeStr), lang: settings.language)
            }
        }

        // 4. 하루 24시간 전체 0건인 경우
        if !hasConnectedCalendars {
            return isCard
                ? L10n.tr(.noCalendarsWithSettings, lang: settings.language)
                : L10n.tr(.noCalendars, lang: settings.language)
        }
        return isCard
            ? L10n.tr(.noEventsToday, lang: settings.language)
            : L10n.tr(.noEventsShort, lang: settings.language)
    }

    var body: some View {
        let text = Self.tooltipText(
            for: allDayEvents,
            outOfRangeEvents: outOfRangeEvents,
            hasTimedEventsInRange: hasTimedEventsInRange,
            hasConnectedCalendars: hasConnectedCalendars,
            settings: settings
        )
        let iconName: String = {
            if !allDayEvents.isEmpty {
                return "calendar.badge.clock"
            } else if !outOfRangeEvents.isEmpty {
                return "clock.badge.exclamationmark"
            } else if !hasConnectedCalendars {
                return "calendar.badge.exclamationmark"
            } else {
                return "calendar"
            }
        }()

        HStack(spacing: 4.5) {
            Image(systemName: iconName)
                .font(.system(size: 9.5, weight: .semibold))
                .foregroundStyle(isDarkTheme ? Color.white.opacity(0.7) : Color.black.opacity(0.6))

            Text(text)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(isDarkTheme ? Color.white.opacity(0.9) : Color.black.opacity(0.85))
                .lineLimit(1)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            VisualEffectBlur(
                material: .popover,
                blendingMode: .behindWindow,
                state: .active
            )
            .clipShape(Capsule())
        )
        .background(
            Capsule()
                .fill(isDarkTheme ? Color.black.opacity(0.85) : Color.white.opacity(0.75))
        )
        .overlay(
            Capsule()
                .stroke(
                    LinearGradient(
                        colors: isDarkTheme ? [
                            Color.white.opacity(0.35),
                            Color.white.opacity(0.10)
                        ] : [
                            Color.black.opacity(0.18),
                            Color.black.opacity(0.08)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.8
                )
        )
        .shadow(color: Color.black.opacity(isDarkTheme ? 0.25 : 0.15), radius: 6, x: 0, y: 3)
    }
}

// MARK: - 8. 캘린더 접근 권한 안내 뷰 (PermissionNoticeTooltipView)
private struct PermissionNoticeTooltipView: View {
    let settings: AppSettings

    @Environment(\.colorScheme) private var colorScheme
    private var isDarkTheme: Bool {
        settings.eventCardTheme.isDark(for: colorScheme)
    }

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.orange)

            Text(L10n.tr(.permissionNeeded, lang: settings.language))
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(isDarkTheme ? Color.white : Color.black.opacity(0.9))
                .lineLimit(1)

            Button(action: {
                CalendarService.openPrivacySettings()
                PopoverPanel.shared.hide(delayed: false)
            }) {
                Text(L10n.tr(.openSystemPrivacy, lang: settings.language))
                    .font(.system(size: 9.5, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Color.accentColor)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            VisualEffectBlur(
                material: .popover,
                blendingMode: .behindWindow,
                state: .active
            )
            .clipShape(Capsule())
        )
        .background(
            Capsule()
                .fill(isDarkTheme ? Color.black.opacity(0.88) : Color.white.opacity(0.80))
        )
        .overlay(
            Capsule()
                .stroke(
                    LinearGradient(
                        colors: isDarkTheme ? [
                            Color.orange.opacity(0.55),
                            Color.white.opacity(0.20)
                        ] : [
                            Color.orange.opacity(0.65),
                            Color.black.opacity(0.14)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.8
                )
        )
        .shadow(color: Color.black.opacity(isDarkTheme ? 0.25 : 0.15), radius: 6, x: 0, y: 3)
    }
}

