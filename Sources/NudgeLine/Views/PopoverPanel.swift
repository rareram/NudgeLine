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

    // 빈 영역 툴팁 -> 상세 카드 확장용 상태 (종일 일정 및 당일 미리알림)
    private var pendingAllDayEvents: [CalendarEvent] = []
    private var pendingAllDayReminders: [ReminderItem] = []
    private var pendingTooltipContext: (cursorOffset: CGFloat, isHorizontal: Bool, barPosition: BarPosition, settings: AppSettings)? = nil
    // 시간 지정 미리알림 툴팁 -> 상세 카드 확장용 상태
    private var pendingReminder: ReminderItem? = nil
    private var pendingReminderContext: (offset: CGFloat, isHorizontal: Bool, barPosition: BarPosition, settings: AppSettings)? = nil

    private func clearPendingExpansionState() {
        self.pendingAllDayEvents = []
        self.pendingAllDayReminders = []
        self.pendingTooltipContext = nil
        self.pendingReminder = nil
        self.pendingReminderContext = nil
    }

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

            // 1. 시간 지정 미리알림 툴팁 -> 상세 액션 카드 자동 확장
            if let reminder = pendingReminder, let context = pendingReminderContext {
                expandToReminderCard(reminder: reminder, context: context)
                clearPendingExpansionState()
            }
            // 2. 당일 종일 일정 및 할 일 툴팁 -> 상세 액션 카드 자동 확장
            else if (!pendingAllDayEvents.isEmpty || !pendingAllDayReminders.isEmpty), let context = pendingTooltipContext {
                expandToAllDayCard(events: pendingAllDayEvents, reminders: pendingAllDayReminders, context: context)
                clearPendingExpansionState()
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
    // MARK: - 방향별 그림자 안전 여백 연산
    // [원인/배경: 균일 여백 부여 시 윈도우 프레임이 타임라인 바 영역(폭 2~3pt)을 덮어 호버 깜빡임(진자 루프) 유발 -> 해결 방법: 바를 향하는 방향은 여백 0pt로 물리적 경계를 엄격히 유지하고, 개방된 바깥 방향에만 10pt 여백을 부여하여 순정 그림자 클리핑 방지 -> 기대 효과: 타임라인 바 호버 간섭 0% 보장 및 흰색 배경에서의 부드러운 순정 그림자 보존]
    private func shadowPadding(for barPosition: BarPosition) -> EdgeInsets {
        let margin: CGFloat = 10.0
        switch barPosition {
        case .left:
            return EdgeInsets(top: margin, leading: 0, bottom: margin, trailing: margin)
        case .right:
            return EdgeInsets(top: margin, leading: margin, bottom: margin, trailing: 0)
        case .bottom:
            return EdgeInsets(top: margin, leading: margin, bottom: 0, trailing: margin)
        }
    }

    // [원인/배경: 비대칭 여백 추가 시 윈도우 원점과 크기 보정이 어긋나면 카드의 화면상 시각적 위치가 이동함 -> 해결 방법: 카드 본체 목표 좌표(cardX, cardY)에서 패딩을 차감/가산하여 윈도우 프레임을 역산 -> 기대 효과: 카드의 시각적 렌더링 위치는 이전과 100% 동일하게 유지하면서 여백만 안전하게 확장]
    private func computePanelFrame(
        cardX: CGFloat,
        cardY: CGFloat,
        cardWidth: CGFloat,
        cardHeight: CGFloat,
        barPosition: BarPosition
    ) -> NSRect {
        let pad = shadowPadding(for: barPosition)
        let winX = cardX - pad.leading
        let winY = cardY - pad.bottom
        let winW = cardWidth + pad.leading + pad.trailing
        let winH = cardHeight + pad.top + pad.bottom
        return NSRect(x: winX, y: winY, width: winW, height: winH)
    }

    // 타임라인 바 위치에 따른 카드 앵커링 (말풍선 꼬리를 타임라인 바 방향 에지에 정확히 밀착)
    @ViewBuilder
    private static func anchorCardView(
        _ cardView: AnyView,
        for barPosition: BarPosition
    ) -> some View {
        switch barPosition {
        case .bottom:
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                cardView
            }
        case .right:
            HStack(spacing: 0) {
                Spacer(minLength: 0)
                cardView
            }
        case .left:
            HStack(spacing: 0) {
                cardView
                Spacer(minLength: 0)
            }
        }
    }

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
        clearPendingExpansionState()

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
        var targetWidth = targetDimensions.width
        var targetHeight = targetDimensions.height

        let pad = shadowPadding(for: barPosition)
        let cardView = AnyView(
            renderer.makeView(
                events: events,
                allDayEvents: allDayEvents,
                settings: settings
            )
        )

        let anchoredCardView = AnyView(
            Self.anchorCardView(cardView, for: barPosition)
                .padding(pad)
        )

        if let hosting = hostingView {
            hosting.rootView = anchoredCardView
        } else {
            let hosting = FirstMouseHostingView(rootView: anchoredCardView)
            hosting.appearance = self.appearance
            self.contentView = hosting
            self.hostingView = hosting
        }

        if let hosting = hostingView {
            let fitting = hosting.fittingSize
            if fitting.width > 0 {
                let actualWidth = ceil(fitting.width - pad.leading - pad.trailing)
                if actualWidth > 20 {
                    targetWidth = actualWidth
                }
            }
            if fitting.height > 0 {
                let actualHeight = ceil(fitting.height - pad.top - pad.bottom)
                if actualHeight > 20 {
                    targetHeight = actualHeight
                }
            }
        }

        var finalX: CGFloat
        var finalY: CGFloat

        if isHorizontal {
            let idealFinalX = visibleFrame.minX + blockOffset + (blockLength / 2) - (targetWidth / 2)
            finalX = max(visibleFrame.minX + 8, min(visibleFrame.maxX - targetWidth - 8, idealFinalX))
            finalY = visibleFrame.minY + thickness + 6
        } else {
            let idealFinalY = visibleFrame.maxY - blockOffset - (blockLength / 2) - (targetHeight / 2)
            finalY = max(visibleFrame.minY + 8, min(visibleFrame.maxY - targetHeight - 8, idealFinalY))

            switch barPosition {
            case .left:
                finalX = fullFrame.minX + thickness + 6
            case .right:
                finalX = fullFrame.maxX - thickness - targetWidth - 6
            case .bottom:
                let idealFinalX = visibleFrame.minX + blockOffset + (blockLength / 2) - (targetWidth / 2)
                finalX = max(visibleFrame.minX + 8, min(visibleFrame.maxX - targetWidth - 8, idealFinalX))
                finalY = visibleFrame.minY + thickness + 6
            }
        }

        let isNewCluster = currentClusterId != clusterId || !self.isVisible
        currentClusterId = clusterId

        let finalFrame = computePanelFrame(
            cardX: finalX,
            cardY: finalY,
            cardWidth: targetWidth,
            cardHeight: targetHeight,
            barPosition: barPosition
        )

        if !self.isVisible {
            self.setFrame(finalFrame, display: true, animate: false)
            self.alphaValue = 0.0
            self.orderFrontRegardless()
            NSAnimationContext.runAnimationGroup { ctx in
                ctx.duration = 0.12
                ctx.timingFunction = CAMediaTimingFunction(name: .easeOut)
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
        barPosition: BarPosition,
        settings: AppSettings,
        screen: NSScreen
    ) -> NSRect {
        let visibleFrame = screen.visibleFrame
        let fullFrame = screen.frame
        let thickness = max(settings.barWidth, settings.hoverWidth)

        var finalX: CGFloat
        var finalY: CGFloat

        switch barPosition {
        case .bottom:
            let idealX = visibleFrame.minX + offset - (targetWidth / 2)
            finalX = max(visibleFrame.minX + 4, min(visibleFrame.maxX - targetWidth - 4, idealX))
            finalY = visibleFrame.minY + thickness + 4
        case .left:
            let idealY = visibleFrame.maxY - offset - (targetHeight / 2)
            finalY = max(visibleFrame.minY + 4, min(visibleFrame.maxY - targetHeight - 4, idealY))
            finalX = fullFrame.minX + thickness + 4
        case .right:
            let idealY = visibleFrame.maxY - offset - (targetHeight / 2)
            finalY = max(visibleFrame.minY + 4, min(visibleFrame.maxY - targetHeight - 4, idealY))
            finalX = fullFrame.maxX - thickness - targetWidth - 4
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
            barPosition: barPosition,
            settings: settings,
            screen: screen
        )

        clearPendingExpansionState()

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

        clearPendingExpansionState()
        self.pendingReminder = reminder
        self.pendingReminderContext = (offset, isHorizontal, barPosition, settings)

        let font = NSFont.systemFont(ofSize: 10, weight: .medium)
        let sampleText = "00:00 \(reminder.title) \(reminder.listTitle)"
        let textWidth = (sampleText as NSString).size(withAttributes: [.font: font]).width
        let targetWidth = min(360.0, max(130.0, ceil(textWidth + 36.0)))
        let targetHeight: CGFloat = 24.0

        let finalFrame = calculateTooltipFrame(
            offset: offset,
            targetWidth: targetWidth,
            targetHeight: targetHeight,
            barPosition: barPosition,
            settings: settings,
            screen: screen
        )

        let clusterId = "__REMINDER_TOOLTIP_\(reminder.id)__"

        presentTooltip(
            content: AnyView(ReminderTooltipView(reminder: reminder, settings: settings)),
            frame: finalFrame,
            clusterId: clusterId,
            isDetailMode: true,
            settings: settings
        )
    }

    public func showEmptyScheduleTooltip(
        cursorOffset: CGFloat,
        allDayEvents: [CalendarEvent] = [],
        allDayReminders: [ReminderItem] = [],
        outOfRangeEvents: [CalendarEvent] = [],
        hasTimedEventsInRange: Bool = false,
        hasConnectedCalendars: Bool = true,
        isHorizontal: Bool,
        barPosition: BarPosition,
        settings: AppSettings = .shared
    ) {
        guard let screen = currentTargetScreen() else { return }

        let text = EmptyScheduleTooltipView.tooltipText(
            for: allDayEvents,
            allDayReminders: allDayReminders,
            outOfRangeEvents: outOfRangeEvents,
            hasTimedEventsInRange: hasTimedEventsInRange,
            hasConnectedCalendars: hasConnectedCalendars,
            settings: settings
        )
        let font = NSFont.systemFont(ofSize: 10, weight: .medium)
        let textWidth = (text as NSString).size(withAttributes: [.font: font]).width
        let hasBoth = !allDayEvents.isEmpty && !allDayReminders.isEmpty
        let targetWidth = min(360.0, max(80.0, ceil(textWidth + (hasBoth ? 42.0 : 30.0))))

        let finalFrame = calculateTooltipFrame(
            offset: cursorOffset,
            targetWidth: targetWidth,
            targetHeight: 24.0,
            barPosition: barPosition,
            settings: settings,
            screen: screen
        )

        let clusterId = "__SCHEDULE_STATUS_TOOLTIP__" +
            allDayEvents.map(\.id).sorted().joined(separator: "_") +
            allDayReminders.map(\.id).sorted().joined(separator: "_") +
            outOfRangeEvents.map(\.id).sorted().joined(separator: "_") +
            "_\(hasTimedEventsInRange)_\(hasConnectedCalendars)_\(settings.eventHoverStyle.rawValue)"

        clearPendingExpansionState()
        let hasItems = (!allDayEvents.isEmpty || !allDayReminders.isEmpty)
        if hasItems {
            self.pendingAllDayEvents = allDayEvents
            self.pendingAllDayReminders = allDayReminders
            self.pendingTooltipContext = (cursorOffset, isHorizontal, barPosition, settings)
        }

        presentTooltip(
            content: AnyView(EmptyScheduleTooltipView(
                allDayEvents: allDayEvents,
                allDayReminders: allDayReminders,
                outOfRangeEvents: outOfRangeEvents,
                hasTimedEventsInRange: hasTimedEventsInRange,
                hasConnectedCalendars: hasConnectedCalendars,
                settings: settings
            )),
            frame: finalFrame,
            clusterId: clusterId,
            isDetailMode: hasItems,
            settings: settings
        )
    }

    // 당일 종일 일정 및 할 일 미니 툴팁 -> 상세 액션 카드 자동 확장
    private func expandToAllDayCard(
        events: [CalendarEvent],
        reminders: [ReminderItem] = [],
        context: (cursorOffset: CGFloat, isHorizontal: Bool, barPosition: BarPosition, settings: AppSettings)
    ) {
        guard let screen = currentTargetScreen(), (!events.isEmpty || !reminders.isEmpty) else { return }
        self.currentClusterId = "__ALL_DAY_CARD_EXPANDED__"
        updatePanelAppearance(settings: context.settings)
        self.isDetailMode = true

        var targetWidth: CGFloat = 280.0
        var targetHeight: CGFloat = AllDayWithRemindersPopoverView.calculateTargetHeight(
            events: events,
            reminders: reminders,
            barPosition: context.barPosition
        )

        let pad = shadowPadding(for: context.barPosition)
        let cardView = AnyView(
            AllDayWithRemindersPopoverView(
                events: events,
                reminders: reminders,
                barPosition: context.barPosition,
                settings: context.settings
            )
        )

        let anchoredCardView = AnyView(
            Self.anchorCardView(cardView, for: context.barPosition)
                .padding(pad)
        )

        if let hosting = hostingView {
            hosting.rootView = anchoredCardView
        } else {
            let hosting = FirstMouseHostingView(rootView: anchoredCardView)
            hosting.appearance = self.appearance
            self.contentView = hosting
            self.hostingView = hosting
        }

        if let hosting = hostingView {
            let fitting = hosting.fittingSize
            if fitting.width > 0 {
                let actualWidth = ceil(fitting.width - pad.leading - pad.trailing)
                if actualWidth > 20 {
                    targetWidth = actualWidth
                }
            }
            if fitting.height > 0 {
                let actualHeight = ceil(fitting.height - pad.top - pad.bottom)
                if actualHeight > 20 {
                    targetHeight = actualHeight
                }
            }
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

        let expandedFrame = computePanelFrame(
            cardX: finalX,
            cardY: finalY,
            cardWidth: targetWidth,
            cardHeight: targetHeight,
            barPosition: context.barPosition
        )

        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.16
            ctx.timingFunction = CAMediaTimingFunction(name: .easeOut)
            self.animator().setFrame(expandedFrame, display: true)
        }
    }

    // 시간 지정 미리알림 미니 툴팁 -> 상세 액션 카드 자동 확장
    private func expandToReminderCard(
        reminder: ReminderItem,
        context: (offset: CGFloat, isHorizontal: Bool, barPosition: BarPosition, settings: AppSettings)
    ) {
        guard let screen = currentTargetScreen() else { return }
        self.currentClusterId = "__REMINDER_CARD_EXPANDED_\(reminder.id)__"
        updatePanelAppearance(settings: context.settings)
        self.isDetailMode = true

        let hasWebLink = reminder.url != nil || (reminder.notes?.contains("http://") == true || reminder.notes?.contains("https://") == true)
        var targetWidth: CGFloat = 260.0
        var estimatedContentHeight: CGFloat = 120.0
        if let notes = reminder.notes, !notes.isEmpty {
            estimatedContentHeight += 32.0
        }
        if hasWebLink {
            estimatedContentHeight += 28.0
        }
        var targetHeight = ceil(estimatedContentHeight + (context.isHorizontal ? 8.0 : 0.0))

        let pad = shadowPadding(for: context.barPosition)
        let cardView = AnyView(
            ReminderPopoverCardView(
                reminder: reminder,
                barPosition: context.barPosition,
                settings: context.settings
            )
        )

        let anchoredCardView = AnyView(
            Self.anchorCardView(cardView, for: context.barPosition)
                .padding(pad)
        )

        if let hosting = hostingView {
            hosting.rootView = anchoredCardView
        } else {
            let hosting = FirstMouseHostingView(rootView: anchoredCardView)
            hosting.appearance = self.appearance
            self.contentView = hosting
            self.hostingView = hosting
        }

        if let hosting = hostingView {
            let fitting = hosting.fittingSize
            if fitting.width > 0 {
                let actualWidth = ceil(fitting.width - pad.leading - pad.trailing)
                if actualWidth > 20 {
                    targetWidth = actualWidth
                }
            }
            if fitting.height > 0 {
                let actualHeight = ceil(fitting.height - pad.top - pad.bottom)
                if actualHeight > 20 {
                    targetHeight = actualHeight
                }
            }
        }

        let visibleFrame = screen.visibleFrame
        let fullFrame = screen.frame
        let thickness = max(context.settings.barWidth, context.settings.hoverWidth)

        var finalX: CGFloat
        var finalY: CGFloat

        if context.isHorizontal {
            let idealFinalX = visibleFrame.minX + context.offset - (targetWidth / 2)
            finalX = max(visibleFrame.minX + 8, min(visibleFrame.maxX - targetWidth - 8, idealFinalX))
            finalY = visibleFrame.minY + thickness + 6
        } else {
            let idealFinalY = visibleFrame.maxY - context.offset - (targetHeight / 2)
            finalY = max(visibleFrame.minY + 8, min(visibleFrame.maxY - targetHeight - 8, idealFinalY))

            switch context.barPosition {
            case .left:
                finalX = fullFrame.minX + thickness + 6
            case .right:
                finalX = fullFrame.maxX - thickness - targetWidth - 6
            case .bottom:
                finalX = visibleFrame.minX + context.offset - (targetWidth / 2)
                finalY = visibleFrame.minY + thickness + 6
            }
        }

        let expandedFrame = computePanelFrame(
            cardX: finalX,
            cardY: finalY,
            cardWidth: targetWidth,
            cardHeight: targetHeight,
            barPosition: context.barPosition
        )

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
            targetHeight: 24.0,
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
            clearPendingExpansionState()
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
                self.clearPendingExpansionState()
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
            ? AppSettings.petSnoozeAccentColor(isDark: isDarkTheme)
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
                                            indicatorColor.opacity(isDarkTheme ? 0.38 : 0.32),
                                            indicatorColor.opacity(isDarkTheme ? 0.22 : 0.18)
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
                                                isDarkTheme ? Color.white.opacity(0.70) : Color.white.opacity(0.95),
                                                indicatorColor.opacity(isDarkTheme ? 0.90 : 0.85)
                                            ],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        ),
                                        lineWidth: 1.2
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
                        .foregroundStyle(isDarkTheme ? Color.white.opacity(0.72) : indicatorColor.opacity(0.85))
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
        // 1단계: 순정 머티리얼 글래스 블러 (사각 잔상 없는 벡터 캡슐 마스킹)
        .background(.ultraThinMaterial, in: Capsule())
        // 2단계: 텍스트 가독성 확보용 캡슐 틴트 레이어
        .background(
            Capsule()
                .fill(isDarkTheme ? Color.black.opacity(0.85) : Color.white.opacity(0.78))
        )
        .clipShape(Capsule())
        // 3단계: 캡슐 외곽선 스트로크
        .overlay(
            Capsule()
                .stroke(
                    settings.isPetSnoozed
                        ? AnyShapeStyle(indicatorColor.opacity(isDarkTheme ? 0.45 : 0.38))
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
        // 1단계: 순정 머티리얼 글래스 블러 (사각 잔상 없는 벡터 캡슐 마스킹)
        .background(.ultraThinMaterial, in: Capsule())
        // 2단계: 텍스트 가독성 확보용 캡슐 틴트 레이어
        .background(
            Capsule()
                .fill(isDarkTheme ? Color.black.opacity(0.85) : Color.white.opacity(0.78))
        )
        .clipShape(Capsule())
        // 3단계: 캡슐 외곽선 스트로크
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
        .contentShape(Capsule())
        .onTapGesture {
            PopoverPanel.shared.setMouseInside(true)
        }
    }
}

// MARK: - 7. 빈 일정 및 종일 일정 안내 툴팁 뷰 (EmptyScheduleTooltipView)
private struct EmptyScheduleTooltipView: View {
    let allDayEvents: [CalendarEvent]
    let allDayReminders: [ReminderItem]
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
        allDayReminders: [ReminderItem] = [],
        outOfRangeEvents: [CalendarEvent] = [],
        hasTimedEventsInRange: Bool = false,
        hasConnectedCalendars: Bool = true,
        settings: AppSettings
    ) -> String {
        let isCard = (settings.eventHoverStyle == .card)

        // 1. 종일 일정과 당일 미리알림이 모두 있는 경우
        if !allDayEvents.isEmpty && !allDayReminders.isEmpty {
            let allDayTitle = allDayEvents[0].title(lang: settings.language)
            let calText = allDayEvents.count == 1 ? allDayTitle : "\(allDayTitle) +\(allDayEvents.count - 1)"
            let remText = L10n.tr(.allDayRemindersNotice(allDayReminders.count), lang: settings.language)
            return "\(calText)  │  \(remText)"
        }

        // 2. 당일 미리알림만 있는 경우 (종일 일정 없음)
        if allDayEvents.isEmpty && !allDayReminders.isEmpty {
            let firstTitle = allDayReminders[0].title
            let others = allDayReminders.count - 1
            return L10n.tr(.todayRemindersOnlyNotice(firstTitle, others), lang: settings.language)
        }

        // 3. 종일 일정과 범위 외 일정이 모두 있는 경우
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

        // 4. 종일 일정만 있는 경우
        if !allDayEvents.isEmpty {
            let title = allDayEvents[0].title(lang: settings.language)
            let otherCount = allDayEvents.count - 1

            if hasTimedEventsInRange {
                return otherCount == 0
                    ? L10n.tr(.allDayNotice(title), lang: settings.language)
                    : L10n.tr(.allDayNoticeWithCount(title, otherCount), lang: settings.language)
            } else {
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

        // 5. 표시 범위 밖 시간 일정만 있는 경우
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

        // 6. 하루 24시간 전체 0건인 경우
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
        let hasBoth = !allDayEvents.isEmpty && !allDayReminders.isEmpty
        let iconColor = isDarkTheme ? Color.white.opacity(0.7) : Color.black.opacity(0.6)
        let textColor = isDarkTheme ? Color.white.opacity(0.9) : Color.black.opacity(0.85)

        HStack(spacing: 4.5) {
            if hasBoth {
                // 일정과 미리알림 병기 렌더링
                let allDayTitle = allDayEvents[0].title(lang: settings.language)
                let calText = allDayEvents.count == 1 ? allDayTitle : "\(allDayTitle) +\(allDayEvents.count - 1)"
                let remText = L10n.tr(.allDayRemindersNotice(allDayReminders.count), lang: settings.language)

                Image(systemName: "calendar")
                    .font(.system(size: 9.5, weight: .semibold))
                    .foregroundStyle(iconColor)

                Text(calText)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(textColor)
                    .lineLimit(1)

                Text("│")
                    .font(.system(size: 9, weight: .light))
                    .foregroundStyle(isDarkTheme ? Color.white.opacity(0.35) : Color.black.opacity(0.25))

                Image(systemName: "checklist")
                    .font(.system(size: 9.5, weight: .semibold))
                    .foregroundStyle(Color.orange.opacity(0.9))

                Text(remText)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(textColor)
                    .lineLimit(1)
            } else {
                let text = Self.tooltipText(
                    for: allDayEvents,
                    allDayReminders: allDayReminders,
                    outOfRangeEvents: outOfRangeEvents,
                    hasTimedEventsInRange: hasTimedEventsInRange,
                    hasConnectedCalendars: hasConnectedCalendars,
                    settings: settings
                )
                let iconName: String = {
                    if !allDayReminders.isEmpty {
                        return "checklist"
                    } else if !allDayEvents.isEmpty {
                        return "calendar"
                    } else if !outOfRangeEvents.isEmpty {
                        return "clock.badge.exclamationmark"
                    } else if !hasConnectedCalendars {
                        return "calendar.badge.exclamationmark"
                    } else {
                        return "calendar"
                    }
                }()

                Image(systemName: iconName)
                    .font(.system(size: 9.5, weight: .semibold))
                    .foregroundStyle(allDayReminders.isEmpty ? iconColor : Color.orange.opacity(0.9))

                Text(text)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(textColor)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        // 1단계: 순정 머티리얼 글래스 블러 (사각 잔상 없는 벡터 캡슐 마스킹)
        .background(.ultraThinMaterial, in: Capsule())
        // 2단계: 텍스트 가독성 확보용 캡슐 틴트 레이어
        .background(
            Capsule()
                .fill(isDarkTheme ? Color.black.opacity(0.85) : Color.white.opacity(0.78))
        )
        .clipShape(Capsule())
        // 3단계: 캡슐 외곽선 스트로크
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
    }
}

// MARK: - 7-1. 종일 일정 및 미리알림 복합 상세 팝오버 뷰 (AllDayWithRemindersPopoverView)
// 당일 종일 일정 및 미리알림 복합 상세 팝오버: 2단 섹션 분리 및 원클릭 체크 완료
private struct AllDayWithRemindersPopoverView: View {
    let events: [CalendarEvent]
    let reminders: [ReminderItem]
    let barPosition: BarPosition
    @ObservedObject var settings: AppSettings

    @State private var completedIds: Set<String> = []

    @Environment(\.colorScheme) private var colorScheme
    private var isDarkTheme: Bool {
        settings.eventCardTheme.isDark(for: colorScheme)
    }

    private var bubbleDirection: BubbleArrowDirection {
        switch barPosition {
        case .left: return .left
        case .right: return .right
        case .bottom: return .bottom
        }
    }

    private var tintColor: Color {
        let opacity = settings.cardOpacity
        return isDarkTheme ? Color.black.opacity(opacity * 0.40) : Color.white.opacity(max(0.85, opacity * 0.90))
    }

    private var textColor: Color {
        isDarkTheme ? Color.white : Color.black.opacity(0.95)
    }

    private var textMuted: Color {
        isDarkTheme ? Color.white.opacity(0.60) : Color.black.opacity(0.55)
    }

    var body: some View {
        let direction = bubbleDirection
        let bubbleShape = SpeechBubbleShape(direction: direction, arrowWidth: 8, arrowHeight: 14, cornerRadius: 10)

        VStack(alignment: .leading, spacing: 8) {
            // 1. 종일 캘린더 일정 섹션 (존재 시)
            if !events.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    // 섹션 헤더: 캘린더 아이콘 + "오늘의 종일 일정 (N)" + 우측 "캘린더 앱 열기"
                    HStack {
                        Image(systemName: "calendar")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Color.accentColor)

                        Text("\(L10n.tr(.allDayEventsSectionTitle, lang: settings.language)) (\(events.count))")
                            .font(.system(size: 10.5, weight: .bold, design: .rounded))
                            .foregroundStyle(textColor)

                        Spacer()

                        Button(action: {
                            if let first = events.first {
                                CalendarAppLauncher.open(event: first)
                            } else {
                                CalendarAppLauncher.open(event: nil)
                            }
                            PopoverPanel.shared.hide(delayed: false)
                        }) {
                            HStack(spacing: 2) {
                                Text(L10n.tr(.openCalendarApp, lang: settings.language))
                                    .font(.system(size: 9, weight: .medium))
                                Image(systemName: "arrow.up.forward")
                                    .font(.system(size: 7.5, weight: .semibold))
                            }
                            .foregroundStyle(Color.accentColor)
                        }
                        .buttonStyle(.plain)
                    }

                    let displayEvents = Array(events.prefix(3))
                    ForEach(displayEvents) { event in
                        let rawCalColor = settings.customColor(for: event.calendarIdentifier) ?? event.defaultColor

                        VStack(alignment: .leading, spacing: 4) {
                            // 캘린더 색상 원형 인디케이터 + 계정/캘린더명
                            HStack(spacing: 5) {
                                Circle()
                                    .fill(rawCalColor)
                                    .frame(width: 7, height: 7)
                                    .overlay(
                                        Circle().stroke(Color.black.opacity(isDarkTheme ? 0.25 : 0.15), lineWidth: 0.5)
                                    )

                                Text("\(event.sourceTitle(lang: settings.language)) • \(event.calendarTitle)")
                                    .font(.system(size: 9.5, weight: .semibold))
                                    .foregroundStyle(textMuted)
                                    .lineLimit(1)
                            }

                            // 일정 제목 (취소/거절 스트라이크스루)
                            Text(event.title(lang: settings.language))
                                .font(.system(size: 12, weight: .bold))
                                .strikethrough(event.isCanceledOrDeclined, color: textMuted)
                                .foregroundStyle(event.isCanceledOrDeclined ? textMuted : textColor)
                                .lineLimit(2)

                            // "하루 종일" 캡슐 배지 + 취소/거절 배지
                            HStack(spacing: 6) {
                                Text(event.formattedTimeRange(lang: settings.language))
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundStyle(textMuted)
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 1.5)
                                    .background(Color.secondary.opacity(isDarkTheme ? 0.20 : 0.12))
                                    .clipShape(Capsule())

                                if event.isCanceled {
                                    Text(L10n.tr(.eventStatusCanceled, lang: settings.language))
                                        .font(.system(size: 9.5, weight: .semibold))
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 1.5)
                                        .background(Color.red.opacity(0.18))
                                        .foregroundStyle(Color.red)
                                        .clipShape(RoundedRectangle(cornerRadius: 3))
                                } else if event.isDeclined {
                                    Text(L10n.tr(.eventStatusDeclined, lang: settings.language))
                                        .font(.system(size: 9.5, weight: .semibold))
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 1.5)
                                        .background(Color.gray.opacity(0.20))
                                        .foregroundStyle(textMuted)
                                        .clipShape(RoundedRectangle(cornerRadius: 3))
                                }
                            }

                            // 본문 메모 미리보기
                            if let cleanNotes = event.displayNotes {
                                HStack(alignment: .top, spacing: 4) {
                                    Image(systemName: "note.text")
                                        .font(.caption2)
                                        .foregroundStyle(textMuted)
                                        .padding(.top, 1)

                                    Text(cleanNotes)
                                        .font(.caption2)
                                        .foregroundStyle(isDarkTheme ? Color.white.opacity(0.80) : Color.black.opacity(0.70))
                                        .lineLimit(2)
                                }
                                .padding(.top, 1)
                            }

                            // 위치 정보
                            if let loc = event.location, !loc.isEmpty {
                                if loc.contains("://") {
                                    HStack(spacing: 4) {
                                        Image(systemName: "mappin.and.ellipse")
                                            .font(.caption2)
                                            .foregroundStyle(textMuted)

                                        Text(loc)
                                            .font(.caption2)
                                            .foregroundStyle(textMuted)
                                            .lineLimit(1)
                                    }
                                } else if let mapUrl = settings.effectivePreferredMapService.url(for: loc) {
                                    actionLinkButton(icon: "mappin.and.ellipse", text: loc, url: mapUrl)
                                }
                            }

                            // 관련 웹 링크 (웨비나, 문서 등)
                            if let webLink = event.webLink {
                                actionLinkButton(icon: "link", text: webLink.displayHost, url: webLink.url, isExternal: true)
                            }

                            // 화상회의 원클릭 바로가기 버튼 (Teams, Zoom, Meet 등 데스크톱 앱 우선)
                            if let meeting = event.meetingInfo {
                                let buttonColor = meeting.platform.brandColor.adjustedForContrast(isDark: isDarkTheme)
                                if !event.isCanceledOrDeclined && meeting.platform != .unverified {
                                    Button(action: {
                                        MeetingAppLauncher.open(meeting: meeting)
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                                            PopoverPanel.shared.hide(delayed: false)
                                        }
                                    }) {
                                        HStack(spacing: 5) {
                                            Image(systemName: meeting.platform.iconName)
                                                .font(.system(size: 11, weight: .semibold))
                                            Text(L10n.tr(.joinMeeting(meeting.platform.rawValue), lang: settings.language))
                                                .font(.system(size: 11, weight: .semibold))
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 4.5)
                                        .background(buttonColor.opacity(isDarkTheme ? 0.24 : 0.14))
                                        .foregroundStyle(buttonColor)
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 6)
                                                .stroke(buttonColor.opacity(isDarkTheme ? 0.45 : 0.30), lineWidth: 0.5)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                    .padding(.top, 2)
                                }
                            }
                        }
                        .padding(.vertical, 2)

                        if event.id != displayEvents.last?.id {
                            Divider()
                                .overlay(isDarkTheme ? Color.white.opacity(0.16) : Color.black.opacity(0.13))
                                .padding(.vertical, 2)
                        }
                    }

                    if events.count > 3 {
                        Button(action: {
                            if let first = events.first {
                                CalendarAppLauncher.open(event: first)
                            } else {
                                CalendarAppLauncher.open(event: nil)
                            }
                            PopoverPanel.shared.hide(delayed: false)
                        }) {
                            Text(L10n.tr(.moreEventsNotice(events.count - 3), lang: settings.language))
                                .font(.system(size: 9.5, weight: .regular))
                                .foregroundStyle(textMuted)
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 1)
                    }
                }
            }

            // 2. 구분선 (일정과 미리알림 둘 다 있을 때)
            if !events.isEmpty && !reminders.isEmpty {
                Divider()
                    .overlay(isDarkTheme ? Color.white.opacity(0.20) : Color.black.opacity(0.15))
                    .padding(.vertical, 1)
            }

            // 3. 당일 미리알림 섹션 (존재 시)
            if !reminders.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "checklist")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Color.orange)

                        Text("\(L10n.tr(.allDayRemindersSectionTitle, lang: settings.language)) (\(reminders.count))")
                            .font(.system(size: 10.5, weight: .bold, design: .rounded))
                            .foregroundStyle(textColor)

                        Spacer()

                        Button(action: {
                            if let url = URL(string: "x-apple-reminderkit://") {
                                NSWorkspace.shared.open(url)
                            }
                            PopoverPanel.shared.hide(delayed: false)
                        }) {
                            HStack(spacing: 2) {
                                Text(L10n.tr(.openRemindersApp, lang: settings.language))
                                    .font(.system(size: 9, weight: .medium))
                                Image(systemName: "arrow.up.forward")
                                    .font(.system(size: 7.5, weight: .semibold))
                            }
                            .foregroundStyle(Color.accentColor)
                        }
                        .buttonStyle(.plain)
                    }

                    let displayReminders = Array(reminders.prefix(4))
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(displayReminders) { item in
                            let isDone = completedIds.contains(item.id)
                            let effectiveColor = item.color.adjustedForContrast(isDark: isDarkTheme)
                            HStack(spacing: 6) {
                                Button(action: {
                                    guard !completedIds.contains(item.id) else { return }
                                    _ = withAnimation(.easeInOut(duration: 0.18)) {
                                        completedIds.insert(item.id)
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                        ReminderService.shared.completeReminder(id: item.id)
                                    }
                                }) {
                                    Image(systemName: isDone ? "checkmark.circle.fill" : "circle")
                                        .font(.system(size: 11, weight: isDone ? .bold : .medium))
                                        .foregroundStyle(isDone ? Color.accentColor : effectiveColor)
                                }
                                .buttonStyle(.plain)

                                Text(item.title)
                                    .font(.system(size: 10.5, weight: .medium))
                                    .foregroundStyle(isDone ? textMuted : textColor)
                                    .strikethrough(isDone, color: textMuted)
                                    .lineLimit(1)

                                Spacer(minLength: 4)

                                if !item.listTitle.isEmpty {
                                    Text(item.listTitle)
                                        .font(.system(size: 8.5, weight: .medium))
                                        .foregroundStyle(effectiveColor.opacity(0.90))
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 1)
                                        .background(effectiveColor.opacity(isDarkTheme ? 0.18 : 0.12))
                                        .clipShape(RoundedRectangle(cornerRadius: 3))
                                        .lineLimit(1)
                                }
                            }
                            .frame(height: 20)
                        }
                    }

                    if reminders.count > 4 {
                        Button(action: {
                            if let url = URL(string: "x-apple-reminderkit://") {
                                NSWorkspace.shared.open(url)
                            }
                            PopoverPanel.shared.hide(delayed: false)
                        }) {
                            Text(L10n.tr(.moreRemindersCount(reminders.count - 4), lang: settings.language))
                                .font(.system(size: 9.5, weight: .regular))
                                .foregroundStyle(textMuted)
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 1)
                    }
                }
            }
        }
        .padding(.leading, direction == .left ? 18 : 12)
        .padding(.trailing, direction == .right ? 18 : 12)
        .padding(.top, 12)
        .padding(.bottom, direction == .bottom ? 18 : 12)
        .frame(width: 280, alignment: .leading)
        .fixedSize(horizontal: true, vertical: false)
        .background(.ultraThinMaterial.opacity(settings.cardOpacity), in: bubbleShape)
        .background(
            bubbleShape
                .fill(tintColor)
                .allowsHitTesting(false)
        )
        .clipShape(bubbleShape)
        .overlay(
            LinearGradient(
                colors: [
                    Color.white.opacity(isDarkTheme ? 0.12 : 0.35),
                    Color.white.opacity(0.0)
                ],
                startPoint: .top,
                endPoint: .center
            )
            .clipShape(bubbleShape)
            .allowsHitTesting(false)
        )
        .overlay(
            bubbleShape
                .stroke(
                    LinearGradient(
                        colors: isDarkTheme ? [
                            Color.white.opacity(0.35),
                            Color.white.opacity(0.10)
                        ] : [
                            Color.black.opacity(0.20),
                            Color.black.opacity(0.10)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.8
                )
                .allowsHitTesting(false)
        )
        .shadow(color: Color.black.opacity(isDarkTheme ? 0.32 : 0.16), radius: 7, x: 0, y: 3.5)
    }

    // ponytail: 위치 및 웹 링크 공통 액션 버튼 렌더러
    @ViewBuilder
    private func actionLinkButton(icon: String, text: String, url: URL, isExternal: Bool = false) -> some View {
        Button(action: {
            NSWorkspace.shared.open(url)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                PopoverPanel.shared.hide(delayed: false)
            }
        }) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                    .foregroundStyle(isDarkTheme ? Color.accentColor : Color.blue.adjustedForContrast(isDark: false, factor: 0.78))

                Text(text)
                    .font(.caption2)
                    .foregroundStyle(isDarkTheme ? Color.white.opacity(0.88) : Color.blue.adjustedForContrast(isDark: false, factor: 0.78))
                    .lineLimit(1)
                    .underline(true, color: (isDarkTheme ? Color.white.opacity(0.35) : Color.blue.opacity(0.35)))

                if isExternal {
                    Image(systemName: "arrow.up.forward")
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundStyle(isDarkTheme ? Color.accentColor : Color.blue.adjustedForContrast(isDark: false, factor: 0.78))
                }
            }
        }
        .buttonStyle(.plain)
    }

    // 종일 일정 및 미리알림 상세 카드의 정밀한 동적 높이 연산
    static func calculateTargetHeight(
        events: [CalendarEvent],
        reminders: [ReminderItem],
        barPosition: BarPosition
    ) -> CGFloat {
        var contentHeight: CGFloat = 0

        // 1. 종일 일정 섹션 높이
        if !events.isEmpty {
            contentHeight += 22.0 // 섹션 헤더 (캘린더 아이콘 + 타이틀 + 앱 열기)
            let displayEvents = Array(events.prefix(3))
            for (idx, event) in displayEvents.enumerated() {
                var itemHeight: CGFloat = 48.0 // 캘린더명(13) + 제목(18) + 시간배지(17)
                if event.displayNotes != nil { itemHeight += 20.0 }
                if let loc = event.location, !loc.isEmpty { itemHeight += 16.0 }
                if event.webLink != nil { itemHeight += 16.0 }
                if event.meetingInfo != nil && !event.isCanceledOrDeclined && event.meetingInfo?.platform != .unverified {
                    itemHeight += 28.0
                }
                contentHeight += itemHeight
                if idx < displayEvents.count - 1 {
                    contentHeight += 8.0 // 아이템 간 구분선 및 간격
                }
            }
            if events.count > 3 {
                contentHeight += 18.0 // 외 N건 더보기
            }
        }

        // 2. 섹션 간 구분선 높이
        if !events.isEmpty && !reminders.isEmpty {
            contentHeight += 12.0
        }

        // 3. 미리알림 섹션 높이
        if !reminders.isEmpty {
            contentHeight += 22.0 // 섹션 헤더
            let displayCount = min(4, reminders.count)
            contentHeight += CGFloat(displayCount) * 24.0 // 각 아이템 높이
            if reminders.count > 4 {
                contentHeight += 18.0 // 외 N개 더보기
            }
        }

        // 4. 말풍선 위아래 내부 패딩 반영 (bottom 화살표는 30pt, 좌/우는 24pt)
        let verticalBubblePadding: CGFloat = (barPosition == .bottom ? 30.0 : 24.0)
        return max(60.0, ceil(contentHeight + verticalBubblePadding))
    }
}

// MARK: - 7-2. 시간 지정 미리알림 단독 상세 팝오버 뷰 (ReminderPopoverCardView)
// 시간 지정 미리알림 호버 시 원클릭 완료 및 앱 바로가기를 제공하는 점진적 공개 액션 카드
private struct ReminderPopoverCardView: View {
    let reminder: ReminderItem
    let barPosition: BarPosition
    @ObservedObject var settings: AppSettings

    @State private var isDone: Bool = false

    @Environment(\.colorScheme) private var colorScheme
    private var isDarkTheme: Bool {
        settings.eventCardTheme.isDark(for: colorScheme)
    }

    private var bubbleDirection: BubbleArrowDirection {
        switch barPosition {
        case .left: return .left
        case .right: return .right
        case .bottom: return .bottom
        }
    }

    private var tintColor: Color {
        let opacity = settings.cardOpacity
        // 라이트 모드: 흰색 바탕 위에서 카드가 날아가지 않도록 충분한 불투명도(0.85)를 확보하여 내부 텍스트 가독성 보호
        return isDarkTheme ? Color.black.opacity(opacity * 0.40) : Color.white.opacity(max(0.85, opacity * 0.90))
    }

    private var effectiveReminderColor: Color {
        reminder.color.adjustedForContrast(isDark: isDarkTheme)
    }

    private var textColor: Color {
        isDarkTheme ? Color.white : Color.black.opacity(0.95)
    }

    private var textSecondary: Color {
        isDarkTheme ? Color.white.opacity(0.72) : Color.black.opacity(0.70)
    }

    private var textMuted: Color {
        isDarkTheme ? Color.white.opacity(0.60) : Color.black.opacity(0.55)
    }

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }()

    private var priorityInfo: (text: String, color: Color)? {
        switch reminder.priority {
        case 1...4:
            return ("!!!", Color.red.adjustedForContrast(isDark: isDarkTheme))
        case 5:
            return ("!!", Color.orange.adjustedForContrast(isDark: isDarkTheme))
        case 6...9:
            return ("!", Color.blue.adjustedForContrast(isDark: isDarkTheme))
        default:
            return nil
        }
    }

    private var timeStatusInfo: (isOverdue: Bool, text: String, color: Color) {
        let now = Date()
        let diffSeconds = reminder.dueDate.timeIntervalSince(now)
        let diffMinutes = Int(diffSeconds / 60)
        let timeStr = Self.timeFormatter.string(from: reminder.dueDate)
        let isKo = settings.language.isKorean

        if diffMinutes < 0 {
            let overdueMinutes = -diffMinutes
            let overdueText: String
            if overdueMinutes < 60 {
                overdueText = isKo ? "\(overdueMinutes)분 지남" : "\(overdueMinutes)m overdue"
            } else if overdueMinutes < 1440 {
                let hours = overdueMinutes / 60
                overdueText = isKo ? "\(hours)시간 지남" : "\(hours)h overdue"
            } else {
                overdueText = isKo ? "지남" : "Overdue"
            }
            let warningColor = Color.red.adjustedForContrast(isDark: isDarkTheme)
            return (true, "\(timeStr) (\(overdueText))", warningColor)
        } else if diffMinutes <= 60 {
            let soonText: String
            if diffMinutes == 0 {
                soonText = isKo ? "곧 마감" : "Due now"
            } else {
                soonText = isKo ? "\(diffMinutes)분 후" : "in \(diffMinutes)m"
            }
            return (false, "\(timeStr) (\(soonText))", effectiveReminderColor)
        } else {
            return (false, timeStr, effectiveReminderColor)
        }
    }

    private var effectiveWebLink: URL? {
        if let url = reminder.url {
            return url
        }
        if let notes = reminder.notes, !notes.isEmpty {
            let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
            let matches = detector?.matches(in: notes, options: [], range: NSRange(location: 0, length: (notes as NSString).length))
            return matches?.first?.url
        }
        return nil
    }

    var body: some View {
        let direction = bubbleDirection
        let bubbleShape = SpeechBubbleShape(direction: direction, arrowWidth: 8, arrowHeight: 14, cornerRadius: 10)

        VStack(alignment: .leading, spacing: 7) {
            // 1. 헤더: 소속 목록 도트 + 이름 + 우측 "미리알림 열기" 액션 버튼
            HStack(spacing: 5) {
                Circle()
                    .fill(effectiveReminderColor)
                    .frame(width: 7, height: 7)
                    .overlay(
                        Circle().stroke(Color.black.opacity(isDarkTheme ? 0.25 : 0.18), lineWidth: 0.5)
                    )

                Text(reminder.listTitle.isEmpty ? "Reminders" : reminder.listTitle)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(textMuted)
                    .lineLimit(1)

                Spacer()

                Button(action: {
                    if let url = URL(string: "x-apple-reminderkit://") {
                        NSWorkspace.shared.open(url)
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                        PopoverPanel.shared.hide(delayed: false)
                    }
                }) {
                    HStack(spacing: 2) {
                        Text(L10n.tr(.openRemindersApp, lang: settings.language))
                            .font(.system(size: 9, weight: .medium))
                        Image(systemName: "arrow.up.forward")
                            .font(.system(size: 7.5, weight: .semibold))
                    }
                    .foregroundStyle(isDarkTheme ? Color.accentColor : Color.blue.adjustedForContrast(isDark: false, factor: 0.78))
                    .padding(.vertical, 2)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

            // 2. 본문: 대형 원형 체크박스 + 할 일 제목
            HStack(alignment: .top, spacing: 8) {
                Button(action: {
                    guard !isDone else { return }
                    withAnimation(.easeInOut(duration: 0.18)) {
                        isDone = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        ReminderService.shared.completeReminder(id: reminder.id)
                    }
                }) {
                    Image(systemName: isDone ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 13.5, weight: isDone ? .bold : .medium))
                        .foregroundStyle(isDone ? Color.accentColor : effectiveReminderColor)
                        .frame(width: 20, height: 20)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Text(reminder.title)
                    .font(.system(size: 12, weight: .semibold))
                    .strikethrough(isDone, color: textMuted)
                    .foregroundStyle(isDone ? textMuted : textColor)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // 3. 시간, 루틴 반복 및 우선순위 메타
            let timeStatus = timeStatusInfo
            HStack(spacing: 6) {
                HStack(spacing: 3) {
                    Image(systemName: timeStatus.isOverdue ? "exclamationmark.circle.fill" : "clock")
                        .font(.system(size: 8.5))
                        .foregroundStyle(timeStatus.isOverdue ? timeStatus.color : textMuted)

                    Text(timeStatus.text)
                        .font(.system(size: 10, weight: timeStatus.isOverdue ? .semibold : .medium, design: .rounded))
                        .foregroundStyle(timeStatus.color)
                }

                if let recurrence = reminder.recurrenceText(isKorean: settings.language.isKorean) {
                    HStack(spacing: 2.5) {
                        Image(systemName: "arrow.2.squarepath")
                            .font(.system(size: 7.5, weight: .semibold))
                        Text(recurrence)
                            .font(.system(size: 8.5, weight: .medium))
                    }
                    .foregroundStyle(textSecondary)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1.5)
                    .background(isDarkTheme ? Color.white.opacity(0.08) : Color.black.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 3))
                }

                if let prio = priorityInfo {
                    Text(prio.text)
                        .font(.system(size: 9.5, weight: .black, design: .rounded))
                        .foregroundStyle(prio.color)
                }
            }

            // 4. 본문 메모 미리보기 (존재 시)
            if let notes = reminder.notes, !notes.isEmpty {
                HStack(alignment: .top, spacing: 4) {
                    Image(systemName: "note.text")
                        .font(.system(size: 9))
                        .foregroundStyle(textMuted)
                        .padding(.top, 1)

                    Text(notes)
                        .font(.system(size: 9.5, weight: .regular))
                        .foregroundStyle(textSecondary)
                        .lineLimit(2)
                }
            }

            // 5. 웹 링크 (명시적 URL 또는 본문 링크 존재 시)
            if let targetUrl = effectiveWebLink {
                Button(action: {
                    NSWorkspace.shared.open(targetUrl)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                        PopoverPanel.shared.hide(delayed: false)
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "link")
                            .font(.system(size: 8.5))
                        Text(targetUrl.host ?? targetUrl.absoluteString)
                            .font(.system(size: 9.5, weight: .medium))
                            .lineLimit(1)
                            .underline(true, color: (isDarkTheme ? Color.white.opacity(0.35) : Color.blue.opacity(0.35)))
                        Image(systemName: "arrow.up.forward")
                            .font(.system(size: 7.5, weight: .semibold))
                    }
                    .foregroundStyle(isDarkTheme ? Color.accentColor : Color.blue.adjustedForContrast(isDark: false, factor: 0.78))
                    .padding(.vertical, 2)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.leading, direction == .left ? 18 : 12)
        .padding(.trailing, direction == .right ? 18 : 12)
        .padding(.top, 12)
        .padding(.bottom, direction == .bottom ? 18 : 12)
        .frame(width: 260, alignment: .leading)
        .fixedSize(horizontal: true, vertical: false)
        // 1단계: 순정 머티리얼 글래스 블러
        .background(.ultraThinMaterial.opacity(settings.cardOpacity), in: bubbleShape)
        .background(
            // 2단계: 테마 투명 틴트 레이어
            bubbleShape
                .fill(tintColor)
                .allowsHitTesting(false)
        )
        .clipShape(bubbleShape)
        .overlay(
            // 3단계: 상단 림 라이트 반사 그래디언트
            LinearGradient(
                colors: [
                    Color.white.opacity(isDarkTheme ? 0.12 : 0.35),
                    Color.white.opacity(0.0)
                ],
                startPoint: .top,
                endPoint: .center
            )
            .clipShape(bubbleShape)
            .allowsHitTesting(false)
        )
        .overlay(
            // 4단계: 외곽선 스트로크
            bubbleShape
                .stroke(
                    LinearGradient(
                        colors: isDarkTheme ? [
                            Color.white.opacity(0.35),
                            Color.white.opacity(0.10)
                        ] : [
                            Color.black.opacity(0.22),
                            Color.black.opacity(0.12)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.8
                )
                .allowsHitTesting(false)
        )
        // 5단계: 순정 부드러운 그림자
        .shadow(color: Color.black.opacity(isDarkTheme ? 0.32 : 0.16), radius: 7, x: 0, y: 3.5)
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
        // 1단계: 순정 머티리얼 글래스 블러 (사각 잔상 없는 벡터 캡슐 마스킹)
        .background(.ultraThinMaterial, in: Capsule())
        // 2단계: 텍스트 가독성 확보용 캡슐 틴트 레이어
        .background(
            Capsule()
                .fill(isDarkTheme ? Color.black.opacity(0.88) : Color.white.opacity(0.80))
        )
        .clipShape(Capsule())
        // 3단계: 캡슐 외곽선 스트로크
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
    }
}

