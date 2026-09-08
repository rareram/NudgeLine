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
    private var isMouseInside: Bool = false
    private var hasEnteredPopover: Bool = false
    private var isDetailMode: Bool = false
    private var showGeneration: Int = 0
    private var cancellables = Set<AnyCancellable>()

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
    }

    public func setMouseInside(_ inside: Bool) {
        self.isMouseInside = inside
        if inside {
            self.hasEnteredPopover = true
            hideTimer?.invalidate()
            hideTimer = nil
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

        guard let screen = currentTargetScreen(), !events.isEmpty else { return }

        let renderer = settings.eventHoverStyle.renderer()
        self.isDetailMode = renderer.allowsTransitBridge
        let visibleFrame = screen.visibleFrame
        let fullFrame = screen.frame
        let thickness = max(settings.barWidth, settings.hoverWidth)

        let targetDimensions = renderer.targetSize(
            events: events,
            isHorizontal: isHorizontal
        )
        let targetWidth = targetDimensions.width
        let targetHeight = targetDimensions.height

        let anyView = renderer.makeView(
            events: events,
            settings: settings
        )

        if let hosting = hostingView {
            hosting.rootView = anyView
        } else {
            let hosting = FirstMouseHostingView(rootView: anyView)
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

        let finalFrame = calculateTooltipFrame(
            offset: timeOffset,
            targetWidth: 110.0,
            targetHeight: 24.0,
            isHorizontal: isHorizontal,
            barPosition: barPosition,
            settings: settings,
            screen: screen
        )

        presentTooltip(
            content: AnyView(CurrentTimeTooltipView(currentTime: currentTime, settings: settings)),
            frame: finalFrame,
            clusterId: "__CURRENT_TIME_TOOLTIP__",
            isDetailMode: false
        )
    }

    public func showEmptyScheduleTooltip(
        cursorOffset: CGFloat,
        allDayEvents: [CalendarEvent] = [],
        outOfRangeEvents: [CalendarEvent] = [],
        hasTimedEventsInRange: Bool = false,
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
            "_\(hasTimedEventsInRange)_\(settings.eventHoverStyle.rawValue)"

        presentTooltip(
            content: AnyView(EmptyScheduleTooltipView(
                allDayEvents: allDayEvents,
                outOfRangeEvents: outOfRangeEvents,
                hasTimedEventsInRange: hasTimedEventsInRange,
                settings: settings
            )),
            frame: finalFrame,
            clusterId: clusterId,
            isDetailMode: false
        )
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
            isDetailMode: true // 시스템 설정 열기 버튼을 클릭할 수 있도록 마우스 브릿지를 유지합니다.
        )
    }

    public func showUpdateNotice(
        cursorOffset: CGFloat,
        version: String,
        isHorizontal: Bool,
        barPosition: BarPosition,
        settings: AppSettings = .shared
    ) {
        guard let screen = currentTargetScreen() else { return }

        let targetWidth: CGFloat = settings.language.isKorean ? 240.0 : 270.0
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
            content: AnyView(UpdateNoticeTooltipView(version: version, settings: settings)),
            frame: finalFrame,
            clusterId: "__UPDATE_NOTICE__",
            isDetailMode: true // 지금 재시작 버튼 클릭을 위해 마우스 브릿지를 활성화합니다.
        )
    }

    // 여러 소형 툴팁(현재 시각, 빈 일정 안내, 권한 알림 등)을 공통 페이드 애니메이션으로 표시합니다.
    private func presentTooltip(
        content: AnyView,
        frame: NSRect,
        clusterId: String,
        isDetailMode: Bool
    ) {
        showGeneration += 1
        hasEnteredPopover = false
        hideTimer?.invalidate()
        hideTimer = nil
        self.isDetailMode = isDetailMode

        if let hosting = hostingView {
            hosting.rootView = content
        } else {
            let hosting = FirstMouseHostingView(rootView: content)
            self.contentView = hosting
            self.hostingView = hosting
        }

        let isNew = !self.isVisible || currentClusterId != clusterId
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
                self.isMouseInside = false
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
                self.isMouseInside = false
                self.hasEnteredPopover = false
            }
        })
    }
}

// MARK: - 6. 현재 시각 미니 툴팁 뷰 (CurrentTimeTooltipView)
private struct CurrentTimeTooltipView: View {
    let currentTime: Date
    let settings: AppSettings

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "M.d (E) HH:mm"
        return f
    }()

    @Environment(\.colorScheme) private var colorScheme
    private var isDarkTheme: Bool {
        settings.eventCardTheme.isDark(for: colorScheme)
    }

    var body: some View {
        HStack(spacing: 3.5) {
            Circle()
                .fill(settings.effectiveCurrentTimeColor())
                .frame(width: 5, height: 5)
                .shadow(color: settings.effectiveCurrentTimeColor().opacity(0.6), radius: 2)

            Text(Self.timeFormatter.string(from: currentTime))
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(isDarkTheme ? Color.white : Color.black.opacity(0.9))
                .lineLimit(1)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            VisualEffectBlur(
                material: isDarkTheme ? .hudWindow : .popover,
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
        .preferredColorScheme(isDarkTheme ? .dark : .light)
    }
}

// MARK: - 7. 빈 일정 및 종일 일정 안내 툴팁 뷰 (EmptyScheduleTooltipView)
private struct EmptyScheduleTooltipView: View {
    let allDayEvents: [CalendarEvent]
    let outOfRangeEvents: [CalendarEvent]
    let hasTimedEventsInRange: Bool
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
        return isCard
            ? L10n.tr(.noEventsToday, lang: settings.language)
            : L10n.tr(.noEventsShort, lang: settings.language)
    }

    var body: some View {
        let text = Self.tooltipText(
            for: allDayEvents,
            outOfRangeEvents: outOfRangeEvents,
            hasTimedEventsInRange: hasTimedEventsInRange,
            settings: settings
        )
        let iconName: String = {
            if !allDayEvents.isEmpty {
                return "calendar.badge.clock"
            } else if !outOfRangeEvents.isEmpty {
                return "clock.badge.exclamationmark"
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
                material: isDarkTheme ? .hudWindow : .popover,
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
        .preferredColorScheme(isDarkTheme ? .dark : .light)
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
                material: isDarkTheme ? .hudWindow : .popover,
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
        .preferredColorScheme(isDarkTheme ? .dark : .light)
    }
}

// MARK: - 8. 새 버전 업데이트 안내 미니 툴팁 (UpdateNoticeTooltipView)
public struct UpdateNoticeTooltipView: View {
    public let version: String
    @ObservedObject public var settings: AppSettings

    public init(version: String, settings: AppSettings = .shared) {
        self.version = version
        self.settings = settings
    }

    @Environment(\.colorScheme) private var colorScheme
    private var isDarkTheme: Bool {
        settings.eventCardTheme.isDark(for: colorScheme)
    }

    public var body: some View {
        HStack(spacing: 7) {
            Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.accentColor)

            Text(L10n.tr(.newVersionReadyNotice(version), lang: settings.language))
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(isDarkTheme ? Color.white.opacity(0.92) : Color.black.opacity(0.85))
                .lineLimit(1)

            Spacer(minLength: 2)

            Button(action: {
                PopoverPanel.shared.hide(delayed: false)
                UpdateService.shared.applyOrRestart()
            }) {
                Text(L10n.tr(.restartNow, lang: settings.language))
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
                material: isDarkTheme ? .hudWindow : .popover,
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
                            Color.accentColor.opacity(0.55),
                            Color.white.opacity(0.20)
                        ] : [
                            Color.accentColor.opacity(0.65),
                            Color.black.opacity(0.14)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.8
                )
        )
        .shadow(color: Color.black.opacity(isDarkTheme ? 0.25 : 0.15), radius: 6, x: 0, y: 3)
        .preferredColorScheme(isDarkTheme ? .dark : .light)
    }
}

